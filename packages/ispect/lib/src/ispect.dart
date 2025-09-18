import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

/// The main entry point for initializing and managing logging/error handling.
final class ISpect {
  const ISpect._();

  static late ISpectify _logger;
  static bool _isInitialized = false;
  static List<String> _filters = [];

  /// Returns the global logger instance.
  static ISpectify get logger {
    if (!_isInitialized) {
      throw StateError(
        'ISpect is not initialized. Call ISpect.initialize() first.',
      );
    }
    return _logger;
  }

  /// Initializes the logger instance once.
  /// Returns `true` if initialization was successful.
  static bool initialize(ISpectify logger, {bool force = false}) {
    if (_isInitialized && !force) return false;
    _logger = logger;
    _isInitialized = true;
    logger.info('🚀 ISpect: Successfully initialized.');
    return true;
  }

  /// Disposes current ISpect state (useful for testing or hot restart).
  static void dispose() {
    _isInitialized = false;
    _filters = [];
  }

  /// Reads the `ISpectScopeModel` from the widget tree.
  static ISpectScopeModel read(BuildContext context) =>
      ISpectScopeController.of(context);

  /// Runs the app with centralized logging and error capture.
  static void run<T>(
    T Function() callback, {
    required ISpectify logger,
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
    initialize(logger);
    _filters = filters;

    _setupErrorHandling(
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
      );
    } else {
      callback();
    }

    onInitialized?.call();
  }

  /// Runs code inside a guarded zone for error capturing and logging.
  static void _runInZone<T>(
    T Function() callback, {
    required bool isPrintLoggingEnabled,
    required bool isFlutterPrintEnabled,
    void Function(Object, StackTrace)? onZonedError,
  }) {
    runZonedGuarded(
      callback,
      (error, stackTrace) {
        onZonedError?.call(error, stackTrace);
        if (_shouldHandleError(error.toString(), stackTrace.toString())) {
          logger.handle(
            message: 'Zoned error caught',
            exception: error,
            stackTrace: stackTrace,
          );
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, parent, zone, line) {
          if (isPrintLoggingEnabled && !_containsAnsi(line)) {
            logger.print(line);
          } else if (isFlutterPrintEnabled) {
            parent.print(zone, line);
          }
        },
      ),
    );
  }

  /// Configures global Flutter and platform error handlers.
  static void _setupErrorHandling({
    void Function(Object, StackTrace)? onPlatformDispatcherError,
    void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    void Function(List<dynamic>)? onUncaughtErrors,
  }) {
    logger.info('🚀 ISpect: Setting up error handling.');

    FlutterError.presentError = (details) {
      void handleError() {
        onPresentError?.call(details, details.stack);
        if (_shouldHandleError(
          details.exceptionAsString(),
          details.stack.toString(),
        )) {
          logger.handle(
            message: 'Flutter error presented',
            exception: details,
            stackTrace: details.stack,
          );
        }
      }

      // Try to use addPostFrameCallback, fallback to immediate execution
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) => handleError());
      } catch (_) {
        // If WidgetsBinding is not initialized, handle immediately
        handleError();
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call(error, stack);
      if (_shouldHandleError(error.toString(), stack.toString())) {
        logger.handle(
          message: 'Platform error caught',
          exception: error,
          stackTrace: stack,
        );
      }
      return true;
    };

    FlutterError.onError = (details) {
      onFlutterError?.call(details, details.stack);
      if (_shouldHandleError(details.toString(), details.stack.toString())) {
        logger.error(
          'FlutterErrorDetails',
          exception: details.toString(),
          stackTrace: details.stack,
        );
      }
    };

    logger.good('✅ ISpect: Error handling set up.');
  }

  /// Determines whether the given error should be handled based on active filters.
  static bool _shouldHandleError(String exception, String stack) =>
      _filters.isEmpty ||
      !_filters.any(
        (filter) => exception.contains(filter) || stack.contains(filter),
      );

  /// Checks if a string contains ANSI escape sequences (e.g., for color).
  static bool _containsAnsi(String line) =>
      line.contains(RegExp(r'\x1B\[[0-9;]*[mGKH]'));
}
