import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

/// Service responsible for handling errors across the application.
///
/// This service follows the Single Responsibility Principle by separating
/// error handling logic from the main ISpect class.
class ErrorHandlerService {
  const ErrorHandlerService({
    required this.logger,
    required this.filters,
  });

  final ISpectify logger;
  final List<String> filters;

  /// Configures global Flutter and platform error handlers.
  void setupErrorHandling({
    required ISpectLogOptions options,
    void Function(Object, StackTrace)? onPlatformDispatcherError,
    void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    void Function(List<dynamic>)? onUncaughtErrors,
  }) {
    logger.info('🚀 ISpect: Setting up error handling.');

    if (options.isFlutterPresentHandlingEnabled) {
      _setupPresentErrorHandler(
        onPresentError: onPresentError,
        onUncaughtErrors: onUncaughtErrors,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    }

    if (options.isPlatformDispatcherHandlingEnabled) {
      _setupPlatformDispatcherHandler(
        onPlatformDispatcherError: onPlatformDispatcherError,
        onUncaughtErrors: onUncaughtErrors,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    }

    if (options.isFlutterErrorHandlingEnabled) {
      _setupFlutterErrorHandler(
        onFlutterError: onFlutterError,
        onUncaughtErrors: onUncaughtErrors,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    }

    logger.good('✅ ISpect: Error handling set up.');
  }

  void _setupPresentErrorHandler({
    required void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    required void Function(List<dynamic>)? onUncaughtErrors,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
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
          if (isUncaughtErrorsHandlingEnabled) {
            onUncaughtErrors?.call(<dynamic>[details, details.stack]);
          }
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
  }

  void _setupPlatformDispatcherHandler({
    required void Function(Object, StackTrace)? onPlatformDispatcherError,
    required void Function(List<dynamic>)? onUncaughtErrors,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call(error, stack);
      if (_shouldHandleError(error.toString(), stack.toString())) {
        logger.handle(
          message: 'Platform error caught',
          exception: error,
          stackTrace: stack,
        );
        if (isUncaughtErrorsHandlingEnabled) {
          onUncaughtErrors?.call(<dynamic>[error, stack]);
        }
      }
      return true;
    };
  }

  void _setupFlutterErrorHandler({
    required void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    required void Function(List<dynamic>)? onUncaughtErrors,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    FlutterError.onError = (details) {
      onFlutterError?.call(details, details.stack);
      if (_shouldHandleError(details.toString(), details.stack.toString())) {
        logger.error(
          'FlutterErrorDetails',
          exception: details.toString(),
          stackTrace: details.stack,
        );
        if (isUncaughtErrorsHandlingEnabled) {
          onUncaughtErrors?.call(<dynamic>[details, details.stack]);
        }
      }
    };
  }

  /// Determines whether the given error should be handled based on active filters.
  bool _shouldHandleError(String exception, String stack) =>
      filters.isEmpty ||
      !filters.any(
        (filter) => exception.contains(filter) || stack.contains(filter),
      );

  /// Handles zone errors with appropriate filtering and callbacks.
  void handleZoneError(
    Object error,
    StackTrace stackTrace, {
    required void Function(Object, StackTrace)? onZonedError,
    required void Function(List<dynamic>)? onUncaughtErrors,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    onZonedError?.call(error, stackTrace);
    if (_shouldHandleError(error.toString(), stackTrace.toString())) {
      logger.handle(
        message: 'Zoned error caught',
        exception: error,
        stackTrace: stackTrace,
      );
      if (isUncaughtErrorsHandlingEnabled) {
        onUncaughtErrors?.call(<dynamic>[error, stackTrace]);
      }
    }
  }

  /// Handles print statements in zones with appropriate filtering.
  void handleZonePrint(
    Zone parent,
    ZoneDelegate zoneDelegate,
    Zone zone,
    String line, {
    required bool isPrintLoggingEnabled,
    required bool isFlutterPrintEnabled,
  }) {
    if (isPrintLoggingEnabled && !_containsAnsi(line)) {
      logger.print(line);
    } else if (isFlutterPrintEnabled) {
      parent.print(line);
    }
  }

  /// Checks if a string contains ANSI escape sequences (e.g., for color).
  static bool _containsAnsi(String line) =>
      line.contains(RegExp(r'\x1B\[[0-9;]*[mGKH]'));
}
