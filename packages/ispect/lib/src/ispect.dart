import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

/// `ISpect` is the main entry point responsible for logging and error handling.
final class ISpect {
  const ISpect._();

  static late final ISpectify _logger;

  /// Provides static access to the logger instance.
  static ISpectify get logger {
    if (!_isInitialized) {
      throw StateError(
        'ISpect is not initialized. Call ISpect.initialize() first.',
      );
    }
    return _logger;
  }

  static bool _isInitialized = false;

  /// Initializes ISpect with a given logger instance.
  static void initialize(ISpectify logger) {
    if (_isInitialized) return;
    _logger = logger;
    _isInitialized = true;
    logger.info('🚀 ISpect: Successfully initialized.');
  }

  /// Reads the `ISpectScopeModel` from the given `BuildContext`.
  static ISpectScopeModel read(BuildContext context) =>
      ISpectScopeController.of(context);

  /// Runs the application with error handling and logging.
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
    _setupErrorHandling(
      onPlatformDispatcherError: onPlatformDispatcherError,
      onFlutterError: onFlutterError,
      onPresentError: onPresentError,
      onUncaughtErrors: onUncaughtErrors,
      filters: filters,
    );

    onInit?.call();

    if (isZoneErrorHandlingEnabled) {
      runZonedGuarded(
        callback,
        (error, stackTrace) {
          onZonedError?.call(error, stackTrace);
          if (_shouldHandleError(
            error.toString(),
            stackTrace.toString(),
            filters,
          )) {
            logger.handle(
              exception: error,
              stackTrace: stackTrace,
              message: 'Zoned error caught',
            );
          }
        },
        zoneSpecification: ZoneSpecification(
          print: (_, parent, zone, line) {
            if (isPrintLoggingEnabled && !line.contains('\x1b')) {
              logger.print(line);
            } else if (isFlutterPrintEnabled) {
              parent.print(zone, line);
            }
          },
        ),
      );
    } else {
      callback();
    }

    onInitialized?.call();
  }

  /// Sets up error handling mechanisms.
  static void _setupErrorHandling({
    void Function(Object, StackTrace)? onPlatformDispatcherError,
    void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    void Function(List<dynamic>)? onUncaughtErrors,
    List<String> filters = const [],
  }) {
    logger.info('🚀 ISpect: Setting up error handling.');

    FlutterError.presentError = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPresentError?.call(details, details.stack);
        if (_shouldHandleError(
          details.exceptionAsString(),
          details.stack.toString(),
          filters,
        )) {
          logger.handle(
            exception: details,
            stackTrace: details.stack,
          );
        }
      });
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call(error, stack);
      if (_shouldHandleError(error.toString(), stack.toString(), filters)) {
        logger.handle(
          exception: error,
          stackTrace: stack,
        );
      }
      return true;
    };

    FlutterError.onError = (details) {
      onFlutterError?.call(details, details.stack);
      if (_shouldHandleError(
        details.toString(),
        details.stack.toString(),
        filters,
      )) {
        logger.error(
          'FlutterErrorDetails',
          exception: details.toString(),
          stackTrace: details.stack,
        );
      }
    };

    logger.good('✅ ISpect: Error handling set up.');
  }

  /// Determines whether an error should be handled based on filters.
  static bool _shouldHandleError(
    String exception,
    String stack,
    List<String> filters,
  ) =>
      filters.isEmpty ||
      !filters.any(
        (filter) => exception.contains(filter) || stack.contains(filter),
      );
}
