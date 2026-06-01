import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/errors/ispect_scope_not_found_error.dart';
import 'package:ispect/src/common/extensions/init.dart';
import 'package:ispect/src/common/observers/route_observer.dart';
import 'package:ispect/src/common/services/error_handler_options.dart';
import 'package:ispect/src/common/services/error_handler_service.dart';
import 'package:ispectify/ispectify.dart';

/// The main entry point for initializing and managing logging/error handling.
final class ISpect {
  const ISpect._();

  static ISpectLogger? _logger;
  static bool _isInitialized = false;
  static ErrorHandlerService? _errorHandler;

  /// Returns the global logger instance.
  ///
  /// Lazily creates a default [ISpectLogger] on first access so call-sites
  /// built before [run]/[initialize] (early DI wiring, hot-restart, tests)
  /// don't crash. The returned instance is fully functional but unconfigured —
  /// it has no access to the options or error handler that [run] would set
  /// up. UI integration (panel, observers) requires [run]/[initialize] to be
  /// called explicitly; the lazy fallback only keeps logging usable.
  ///
  /// When `kISpectEnabled` is `false` (default in release builds), the lazy
  /// instance is effectively unreachable from the rest of ISpect and gets
  /// tree-shaken.
  static ISpectLogger get logger {
    if (!_isInitialized) {
      _logger = ISpectLogger();
      _isInitialized = true;
    }
    return _logger!;
  }

  /// Initializes the logger instance once.
  /// Returns `true` if initialization was successful.
  ///
  /// When `kISpectEnabled` is `false`, this method does nothing and returns false.
  static bool initialize(ISpectLogger logger, {bool force = false}) {
    if (!kISpectEnabled) return false;

    if (_isInitialized && !force) return false;
    _logger = logger;
    _isInitialized = true;
    logger.info('🚀 ISpect: Successfully initialized.');
    return true;
  }

  /// Disposes current ISpect state (useful for testing or hot restart).
  static Future<void> dispose() async {
    await _logger?.dispose();
    _isInitialized = false;
    _logger = null;
    _errorHandler = null;
    ISpectNavigatorObserver.resetCurrent();
  }

  /// Reads the nearest [ISpectScopeModel] from the widget tree.
  ///
  /// This is the canonical way to access the scope model; prefer it over
  /// `ISpectScopeController.of(context)`, which is deprecated.
  ///
  /// Throws an [ISpectScopeNotFoundError] if no `ISpectScopeController` is an
  /// ancestor — ensure `ISpectBuilder` wraps the widget that uses this context.
  static ISpectScopeModel read(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<ISpectScopeController>();
    if (inherited == null || inherited.notifier == null) {
      throw ISpectScopeNotFoundError();
    }
    return inherited.notifier!;
  }

  /// Runs the app with centralized logging and error capture.
  ///
  /// If [logger] is not provided, creates a default Flutter logger automatically
  /// using [ISpectFlutter.init()].
  ///
  /// When `kISpectEnabled` is `false` (default), this method simply calls
  /// the callback without any ISpect initialization, enabling tree-shaking.
  ///
  /// Perform binding setup (`WidgetsFlutterBinding.ensureInitialized()`) inside
  /// [callback] or [onInit] rather than before calling [run]: both run in the
  /// guarded zone, so initializing the binding outside it causes a Flutter
  /// "Zone mismatch" warning and can drop errors from the installed handlers.
  ///
  /// ### Example (Simple):
  /// ```dart
  /// ISpect.run(() => runApp(MyApp()));
  /// ```
  ///
  /// ### Example (Custom Logger):
  /// ```dart
  /// final customLogger = ISpectFlutter.init(
  ///   options: ISpectLoggerOptions(...),
  /// );
  /// ISpect.run(() => runApp(MyApp()), logger: customLogger);
  /// ```
  ///
  /// ### Build Commands:
  /// ```bash
  /// # Development (ISpect enabled)
  /// flutter run --dart-define=ISPECT_ENABLED=true
  ///
  /// # Production (ISpect removed via tree-shaking)
  /// flutter build apk
  /// ```
  static void run<T>(
    T Function() callback, {
    ISpectLogger? logger,
    VoidCallback? onInit,
    VoidCallback? onInitialized,
    void Function(Object, StackTrace)? onZonedError,
    bool isPrintLoggingEnabled = !kReleaseMode,
    bool isFlutterPrintEnabled = true,
    bool isZoneErrorHandlingEnabled = true,
    void Function(Object, StackTrace)? onPlatformDispatcherError,
    void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    void Function(Object error, StackTrace? stack)? onUncaughtError,
    ISpectErrorHandlerOptions options = const ISpectErrorHandlerOptions(),
    List<String> filters = const [],
  }) {
    if (!kISpectEnabled) {
      callback();
      return;
    }

    final effectiveLogger = logger ?? ISpectFlutter.init();
    initialize(effectiveLogger, force: true);
    _errorHandler =
        ErrorHandlerService(logger: effectiveLogger, filters: filters);

    _errorHandler!.setupErrorHandling(
      options: options,
      onPlatformDispatcherError: onPlatformDispatcherError,
      onFlutterError: onFlutterError,
      onPresentError: onPresentError,
      onUncaughtError: onUncaughtError,
    );

    // Run init/app/post-init inside the guarded zone so that binding setup
    // (e.g. `WidgetsFlutterBinding.ensureInitialized()`) and `runApp` share the
    // same zone — mixing zones triggers Flutter's "Zone mismatch" warning and
    // can drop errors from the handlers installed above.
    void bootstrap() {
      onInit?.call();
      callback();
      onInitialized?.call();
    }

    if (isZoneErrorHandlingEnabled) {
      _runInZone(
        bootstrap,
        onZonedError: onZonedError,
        isPrintLoggingEnabled: isPrintLoggingEnabled,
        isFlutterPrintEnabled: isFlutterPrintEnabled,
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    } else {
      bootstrap();
    }
  }

  static void _runInZone<T>(
    T Function() callback, {
    required bool isPrintLoggingEnabled,
    required bool isFlutterPrintEnabled,
    required bool isUncaughtErrorsHandlingEnabled,
    void Function(Object, StackTrace)? onZonedError,
    void Function(Object error, StackTrace? stack)? onUncaughtError,
  }) {
    runZonedGuarded(
      callback,
      (error, stackTrace) {
        _errorHandler?.handleZoneError(
          error,
          stackTrace,
          onZonedError: onZonedError,
          onUncaughtError: onUncaughtError,
          isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (parent, zoneDelegate, zone, line) {
          _errorHandler?.handleZonePrint(
            parent,
            zoneDelegate,
            zone,
            line,
            isPrintLoggingEnabled: isPrintLoggingEnabled,
            isFlutterPrintEnabled: isFlutterPrintEnabled,
          );
        },
      ),
    );
  }
}
