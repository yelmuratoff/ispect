import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/common/errors/ispect_scope_not_found_error.dart';
import 'package:ispect/src/common/extensions/init.dart';
import 'package:ispect/src/common/observers/route_observer.dart';
import 'package:ispect/src/common/services/error_handler_options.dart';
import 'package:ispect/src/common/services/error_handler_service.dart';
import 'package:ispect/src/common/utils/logs_file/factory/logs_file_factory.dart';
import 'package:ispectify/ispectify.dart';

/// The main entry point for initializing and managing logging/error handling.
final class ISpect {
  const ISpect._();

  static ISpectLogger? _logger;
  static bool _isInitialized = false;
  static bool _shareCleanupCompleted = false;
  static Future<void>? _shareCleanupFuture;
  static Future<void>? _disposeFuture;
  static ErrorHandlerService? _errorHandler;
  static ({bool enabled, RedactionService service})? _redactionBeforeRun;
  static final Map<ISpectLogger, Future<(Object, StackTrace)?>> _retirements =
      Map<ISpectLogger, Future<(Object, StackTrace)?>>.identity();
  static final NetworkSenderRegistry _senders = NetworkSenderRegistry();

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
  /// instance is created disabled — it retains no history and emits no console
  /// output, so logging through it is a no-op. This keeps diagnostics from
  /// accumulating in memory in production builds where ISpect is gated off.
  static ISpectLogger get logger {
    if (_logger == null) {
      if (kISpectEnabled) _scheduleShareCleanup();
      _logger = kISpectEnabled
          ? ISpectLogger()
          : ISpectLogger(options: ISpectLoggerOptions(enabled: false));
    }
    return _logger!;
  }

  /// Returns the current logger without lazily creating a fallback.
  ///
  /// Lifecycle integrations should use this accessor when capture must remain
  /// inactive before initialization or after [dispose].
  static ISpectLogger? get loggerIfInitialized {
    if (!_isInitialized || _disposeFuture != null) return null;
    return _logger;
  }

  /// Initializes the logger instance once.
  /// Returns `true` if initialization was successful.
  ///
  /// With [force], replacing a different logger starts retiring the previous
  /// instance. [dispose] joins every retirement and surfaces flush failures.
  ///
  /// When `kISpectEnabled` is `false`, this method does nothing and returns false.
  static bool initialize(ISpectLogger logger, {bool force = false}) =>
      _initialize(logger, force: force);

  static bool _initialize(
    ISpectLogger logger, {
    required bool force,
    bool retirePrevious = true,
  }) {
    if (!kISpectEnabled || _disposeFuture != null || logger.isDisposed) {
      return false;
    }

    _scheduleShareCleanup(retryAfterFailure: true);
    if (_isInitialized && !force) return false;
    final previousLogger = _logger;
    _logger = logger;
    _isInitialized = true;
    if (retirePrevious &&
        previousLogger != null &&
        !identical(previousLogger, logger)) {
      _retireLogger(previousLogger);
    }
    logger.info('🚀 ISpect: Successfully initialized.');
    return true;
  }

  static void _retireLogger(ISpectLogger logger) {
    _retirements.putIfAbsent(
      logger,
      () => logger.dispose().then<(Object, StackTrace)?>(
        (_) => null,
        onError: (Object error, StackTrace stackTrace) => (error, stackTrace),
      ),
    );
  }

  static void _scheduleShareCleanup({bool retryAfterFailure = false}) {
    if (!kISpectEnabled || _shareCleanupCompleted) return;

    final pending = _shareCleanupFuture;
    if (pending != null) {
      if (retryAfterFailure) {
        unawaited(
          pending.then<void>(
            (_) {},
            onError: (Object _, StackTrace __) {
              if (identical(_shareCleanupFuture, pending)) {
                _shareCleanupFuture = null;
              }
              _scheduleShareCleanup();
            },
          ),
        );
      }
      return;
    }

    late final Future<void> cleanup;
    cleanup = Future<void>(LogsFileFactory.cleanupStaleShareFiles);
    _shareCleanupFuture = cleanup;
    unawaited(
      cleanup.then<void>(
        (_) {
          _shareCleanupCompleted = true;
          if (identical(_shareCleanupFuture, cleanup)) {
            _shareCleanupFuture = null;
          }
        },
        onError: (Object _, StackTrace __) {
          if (identical(_shareCleanupFuture, cleanup)) {
            _shareCleanupFuture = null;
          }
        },
      ),
    );
  }

  /// Clients registered for request replay/compose (the in-app HTTP composer).
  ///
  /// Empty unless the app opts in via [registerSender]; the composer UI hides
  /// itself when this is empty.
  static List<NetworkRequestSender> get senders => _senders.senders;

  /// Registers a client so the composer can send through it, reusing its base
  /// URL, auth interceptors, and retries.
  ///
  /// A sender with the same id replaces the previous one. No-op when
  /// `kISpectEnabled` is `false`, so production builds neither retain the
  /// client nor expose request sending.
  static void registerSender(NetworkRequestSender sender) {
    if (!kISpectEnabled) return;
    _senders.register(sender);
  }

  /// Removes a client previously passed to [registerSender] by its id.
  static void unregisterSender(String id) => _senders.unregister(id);

  /// Disposes current ISpect state (useful for testing or hot restart).
  ///
  /// Concurrent calls join the same operation. Await completion before
  /// initializing or running ISpect again.
  static Future<void> dispose() {
    final pending = _disposeFuture;
    if (pending != null) return pending;

    final completer = Completer<void>();
    final operation = completer.future;
    _disposeFuture = operation;
    void clearPending() {
      if (identical(_disposeFuture, operation)) {
        _disposeFuture = null;
      }
    }

    late final Future<void> lifecycle;
    try {
      lifecycle = _disposeLifecycle();
    } catch (error, stackTrace) {
      clearPending();
      completer.completeError(error, stackTrace);
      return operation;
    }
    unawaited(
      lifecycle.then<void>(
        (_) {
          clearPending();
          completer.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          clearPending();
          completer.completeError(error, stackTrace);
        },
      ),
    );
    return operation;
  }

  static Future<void> _disposeLifecycle() async {
    final errorHandler = _errorHandler;
    final logger = _logger;
    final retirements = _retirements.values.toList(growable: false);
    _retirements.clear();
    _errorHandler = null;

    (Object, StackTrace)? firstFailure;
    try {
      try {
        errorHandler?.dispose();
      } catch (error, stackTrace) {
        firstFailure = (error, stackTrace);
      }
      try {
        await logger?.dispose();
      } catch (error, stackTrace) {
        firstFailure ??= (error, stackTrace);
      }
      for (final retirement in retirements) {
        final failure = await retirement;
        firstFailure ??= failure;
      }
    } finally {
      _restoreRedactionOverride();
      _isInitialized = false;
      _logger = null;
      _senders.clear();
      ISpectNavigatorObserver.resetCurrent();
    }

    final failure = firstFailure;
    if (failure != null) {
      Error.throwWithStackTrace(failure.$1, failure.$2);
    }
  }

  /// Reads the nearest [ISpectScopeModel] from the widget tree.
  ///
  /// This is the canonical way to access the scope model; prefer it over
  /// `ISpectScopeController.of(context)`, which is deprecated.
  ///
  /// Throws an [ISpectScopeNotFoundError] if no `ISpectScopeController` is an
  /// ancestor — ensure `ISpectBuilder` wraps the widget that uses this context.
  static ISpectScopeModel read(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<ISpectScopeController>();
    if (inherited == null || inherited.notifier == null) {
      throw ISpectScopeNotFoundError();
    }
    return inherited.notifier!;
  }

  /// Like [read] but returns `null` instead of throwing when no
  /// `ISpectScopeController` is an ancestor. Use for context-derived defaults
  /// (e.g. resolving ISpect's own brightness) that must stay safe outside the
  /// scope, such as in tests or detached overlays.
  static ISpectScopeModel? maybeRead(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ISpectScopeController>()
      ?.notifier;

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
  ///
  /// Pass [redactionEnabled] or [redactionService] to override the global
  /// redaction policy for this run. [dispose] restores the policy that was
  /// active before [run]. Set [redactionEnabled] to `false` only for builds
  /// that genuinely need raw payloads.
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
    bool? redactionEnabled,
    RedactionService? redactionService,
  }) {
    if (!kISpectEnabled) {
      callback();
      return;
    }
    if (_disposeFuture != null) {
      throw StateError(
        'Cannot run ISpect while disposal is in progress. '
        'Await ISpect.dispose() before starting a new run.',
      );
    }

    final effectiveLogger = logger ?? ISpectFlutter.init();
    if (effectiveLogger.isDisposed) {
      throw StateError('Cannot run ISpect with a disposed logger.');
    }
    final previousLogger = _logger;
    if (previousLogger != null && !identical(previousLogger, effectiveLogger)) {
      _retireLogger(previousLogger);
    }
    _restoreRedactionOverride();
    if (redactionEnabled != null || redactionService != null) {
      _redactionBeforeRun = (
        enabled: ISpectRedaction.enabled,
        service: ISpectRedaction.service,
      );
      ISpectRedaction.configure(
        enabled: redactionEnabled,
        service: redactionService,
      );
    }

    final initialized = _initialize(
      effectiveLogger,
      force: true,
      retirePrevious: false,
    );
    if (!initialized) {
      throw StateError('ISpect initialization failed.');
    }
    _errorHandler?.dispose();
    _errorHandler = ErrorHandlerService(
      logger: effectiveLogger,
      filters: filters,
    );

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
    final parentZone = Zone.current;
    runZonedGuarded(
      callback,
      (error, stackTrace) {
        final errorHandler = _errorHandler;
        if (errorHandler != null) {
          errorHandler.handleZoneError(
            error,
            stackTrace,
            onZonedError: onZonedError,
            onUncaughtError: onUncaughtError,
            isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
          );
        } else {
          parentZone.handleUncaughtError(error, stackTrace);
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (parent, zoneDelegate, zone, line) {
          final errorHandler = _errorHandler;
          if (errorHandler != null) {
            errorHandler.handleZonePrint(
              parent,
              zoneDelegate,
              zone,
              line,
              isPrintLoggingEnabled: isPrintLoggingEnabled,
              isFlutterPrintEnabled: isFlutterPrintEnabled,
            );
          } else {
            zoneDelegate.print(parent, line);
          }
        },
      ),
    );
  }

  static void _restoreRedactionOverride() {
    final previous = _redactionBeforeRun;
    if (previous == null) return;
    ISpectRedaction.configure(
      enabled: previous.enabled,
      service: previous.service,
    );
    _redactionBeforeRun = null;
  }
}
