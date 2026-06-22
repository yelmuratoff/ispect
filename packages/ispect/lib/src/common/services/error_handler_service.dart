import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/services/error_handler_options.dart';
import 'package:ispectify/ispectify.dart';

/// Installs and owns the app-level error/log handlers (`FlutterError`,
/// `PlatformDispatcher`, guarded-zone, and `print`) and funnels every captured
/// failure through [ISpectLogger.handle].
final class ErrorHandlerService {
  ErrorHandlerService({
    required this.logger,
    required this.filters,
  });

  final ISpectLogger logger;
  final List<String> filters;

  bool _isHandlingPrint = false;

  void setupErrorHandling({
    required ISpectErrorHandlerOptions options,
    void Function(Object, StackTrace)? onPlatformDispatcherError,
    void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    void Function(Object error, StackTrace? stack)? onUncaughtError,
  }) {
    logger.info('🚀 ISpect: Setting up error handling.');

    if (options.isFlutterPresentHandlingEnabled) {
      _setupPresentErrorHandler(
        onPresentError: onPresentError,
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    }

    if (options.isPlatformDispatcherHandlingEnabled) {
      _setupPlatformDispatcherHandler(
        onPlatformDispatcherError: onPlatformDispatcherError,
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    }

    if (options.isFlutterErrorHandlingEnabled) {
      _setupFlutterErrorHandler(
        onFlutterError: onFlutterError,
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled:
            options.isUncaughtErrorsHandlingEnabled,
      );
    }

    logger.good('✅ ISpect: Error handling set up.');
  }

  void _setupPresentErrorHandler({
    required void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    FlutterError.presentError = (details) {
      void report() {
        onPresentError?.call(details, details.stack);
        _report(
          exception: details.exception,
          stack: details.stack,
          logMessage: 'Flutter error presented',
          onUncaughtError: onUncaughtError,
          isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
        );
      }

      try {
        WidgetsBinding.instance.addPostFrameCallback((_) => report());
      } catch (_) {
        report();
      }
    };
  }

  void _setupPlatformDispatcherHandler({
    required void Function(Object, StackTrace)? onPlatformDispatcherError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    PlatformDispatcher.instance.onError = (error, stack) {
      onPlatformDispatcherError?.call(error, stack);
      _report(
        exception: error,
        stack: stack,
        logMessage: 'Platform error caught',
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
      );
      return true;
    };
  }

  void _setupFlutterErrorHandler({
    required void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    FlutterError.onError = (details) {
      onFlutterError?.call(details, details.stack);
      _report(
        exception: details.exception,
        stack: details.stack,
        logMessage: 'Flutter error caught',
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
      );
    };
  }

  void handleZoneError(
    Object error,
    StackTrace stackTrace, {
    required void Function(Object, StackTrace)? onZonedError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    onZonedError?.call(error, stackTrace);
    _report(
      exception: error,
      stack: stackTrace,
      logMessage: 'Zoned error caught',
      onUncaughtError: onUncaughtError,
      isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
    );
  }

  void handleZonePrint(
    Zone parent,
    ZoneDelegate zoneDelegate,
    Zone zone,
    String line, {
    required bool isPrintLoggingEnabled,
    required bool isFlutterPrintEnabled,
  }) {
    if (_isHandlingPrint) {
      zoneDelegate.print(parent, line);
      return;
    }

    _isHandlingPrint = true;
    try {
      if (isPrintLoggingEnabled && !containsAnsi(line)) {
        logger.print(line);
      } else if (isFlutterPrintEnabled) {
        zoneDelegate.print(parent, line);
      }
    } finally {
      _isHandlingPrint = false;
    }
  }

  /// Logs [exception]/[stack] through [ISpectLogger.handle] when it passes the
  /// configured [filters], then forwards it to [onUncaughtError] when uncaught
  /// reporting is enabled.
  void _report({
    required Object exception,
    required StackTrace? stack,
    required String logMessage,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    if (!_shouldHandleError(exception, stack)) return;

    logger.handle(
      message: logMessage,
      exception: exception,
      stackTrace: stack,
    );

    if (isUncaughtErrorsHandlingEnabled) {
      onUncaughtError?.call(exception, stack);
    }
  }

  bool _shouldHandleError(Object exception, StackTrace? stack) {
    if (filters.isEmpty) return true;

    final message = exception.toString();
    final stackText = stack?.toString() ?? '';
    return !filters.any(
      (filter) => message.contains(filter) || stackText.contains(filter),
    );
  }
}
