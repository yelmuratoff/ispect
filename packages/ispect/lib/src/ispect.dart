import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/extensions/init.dart';
import 'package:ispect/src/common/services/error_handler_service.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

/// The main entry point for initializing and managing logging/error handling.
final class ISpect {
  const ISpect._();

  static ISpectLogger? _logger;
  static bool _isInitialized = false;
  static bool _warnedAboutLazyInit = false;
  static ErrorHandlerService? _errorHandler;

  /// Returns the global logger instance.
  ///
  /// Lazily creates a default [ISpectLogger] on first access so call-sites
  /// built before [run]/[initialize] (early DI wiring, hot-restart, tests)
  /// don't crash. The returned instance is fully functional, but it has no
  /// access to the options/error handler that [run] would have configured —
  /// so if `kISpectEnabled` is `true` and no explicit initialization happened,
  /// a one-time warning is emitted via [debugPrint] to nudge the developer
  /// toward calling [initialize] or [run].
  ///
  /// When `kISpectEnabled` is `false` (default in release builds), the lazy
  /// fallback stays silent — the logger is effectively unreachable from the
  /// rest of ISpect and gets tree-shaken.
  static ISpectLogger get logger {
    if (!_isInitialized) {
      _logger = ISpectLogger();
      _isInitialized = true;
      if (kISpectEnabled && !_warnedAboutLazyInit) {
        _warnedAboutLazyInit = true;
        debugPrint(
          '⚠️ ISpect: logger accessed before initialize(). Falling back to '
          'a default ISpectLogger. Call ISpect.initialize() or ISpect.run() '
          'to wire up options, error handling and UI integration.',
        );
      }
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
  ///
  /// Resets the lazy-init warning flag so a subsequent uninitialized access
  /// emits the warning again — dispose is treated as a full reset, not a
  /// suppression.
  static Future<void> dispose() async {
    await _logger?.dispose();
    _isInitialized = false;
    _logger = null;
    _errorHandler = null;
    _warnedAboutLazyInit = false;
  }

  /// Reads the nearest [ISpectScopeModel] from the widget tree.
  ///
  /// This is the canonical way to access the scope model; prefer it over
  /// `ISpectScopeController.of(context)`, which is deprecated.
  ///
  /// Throws a [FlutterError] if no `ISpectScopeController` is an ancestor —
  /// ensure `ISpectBuilder` wraps the widget that uses this context.
  static ISpectScopeModel read(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<ISpectScopeController>();
    if (inherited == null || inherited.notifier == null) {
      throw FlutterError(
        'ISpect.read() called with a context that does not contain an '
        'ISpectScopeController.\n'
        'Ensure that ISpectBuilder is an ancestor of the widget using this '
        'context.',
      );
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
    void Function(List<dynamic>)? onUncaughtErrors,
    ISpectLogOptions options = const ISpectLogOptions(),
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
      onUncaughtErrors: onUncaughtErrors,
    );

    onInit?.call();

    if (isZoneErrorHandlingEnabled) {
      _runInZone(
        callback,
        onZonedError: onZonedError,
        isPrintLoggingEnabled: isPrintLoggingEnabled,
        isFlutterPrintEnabled: isFlutterPrintEnabled,
        onUncaughtErrors: onUncaughtErrors,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    } else {
      callback();
    }

    onInitialized?.call();
  }

  static void _runInZone<T>(
    T Function() callback, {
    required bool isPrintLoggingEnabled,
    required bool isFlutterPrintEnabled,
    required bool isUncaughtErrorsHandlingEnabled,
    void Function(Object, StackTrace)? onZonedError,
    void Function(List<dynamic>)? onUncaughtErrors,
  }) {
    runZonedGuarded(
      callback,
      (error, stackTrace) {
        _errorHandler?.handleZoneError(
          error,
          stackTrace,
          onZonedError: onZonedError,
          onUncaughtErrors: onUncaughtErrors,
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
