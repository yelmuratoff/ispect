import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/features/ispect/options.dart';
import 'package:ispectify/ispectify.dart';

class ErrorHandlerService {
  ErrorHandlerService({
    required this.logger,
    required this.filters,
  });

  final ISpectLogger logger;
  final List<String> filters;

  bool _isHandlingPrint = false;
  static final RegExp _ansiPattern = RegExp(r'\x1B\[[0-9;]*[mGKH]');

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

        final snapshot = _captureStrings(
          details.exceptionAsString(),
          details.stack,
        );

        if (_shouldHandleError(snapshot)) {
          logger.handle(
            message: 'Flutter error presented',
            exception: details,
            stackTrace: details.stack,
          );
          _notifyUncaughtErrors(
            <dynamic>[details, details.stack],
            isEnabled: isUncaughtErrorsHandlingEnabled,
            callback: onUncaughtErrors,
          );
        }
      }

      try {
        WidgetsBinding.instance.addPostFrameCallback((_) => handleError());
      } catch (_) {
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

      final snapshot = _captureStrings(error, stack);

      if (_shouldHandleError(snapshot)) {
        logger.handle(
          message: 'Platform error caught',
          exception: error,
          stackTrace: stack,
        );
        _notifyUncaughtErrors(
          <dynamic>[error, stack],
          isEnabled: isUncaughtErrorsHandlingEnabled,
          callback: onUncaughtErrors,
        );
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

      final snapshot = _captureStrings(details, details.stack);

      if (_shouldHandleError(snapshot)) {
        logger.error(
          'FlutterErrorDetails',
          exception: snapshot.message,
          stackTrace: details.stack,
        );
        _notifyUncaughtErrors(
          <dynamic>[details, details.stack],
          isEnabled: isUncaughtErrorsHandlingEnabled,
          callback: onUncaughtErrors,
        );
      }
    };
  }

  bool _shouldHandleError(_ErrorSnapshot snapshot) {
    if (filters.isEmpty) return true;

    return !filters.any(
      (filter) =>
          snapshot.message.contains(filter) || snapshot.stack.contains(filter),
    );
  }

  void _notifyUncaughtErrors(
    List<dynamic> errorData, {
    required bool isEnabled,
    required void Function(List<dynamic>)? callback,
  }) {
    if (isEnabled) {
      callback?.call(errorData);
    }
  }

  void handleZoneError(
    Object error,
    StackTrace stackTrace, {
    required void Function(Object, StackTrace)? onZonedError,
    required void Function(List<dynamic>)? onUncaughtErrors,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    onZonedError?.call(error, stackTrace);

    final snapshot = _captureStrings(error, stackTrace);

    if (_shouldHandleError(snapshot)) {
      logger.handle(
        message: 'Zoned error caught',
        exception: error,
        stackTrace: stackTrace,
      );
      _notifyUncaughtErrors(
        <dynamic>[error, stackTrace],
        isEnabled: isUncaughtErrorsHandlingEnabled,
        callback: onUncaughtErrors,
      );
    }
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
      if (isPrintLoggingEnabled && !_containsAnsi(line)) {
        logger.print(line);
      } else if (isFlutterPrintEnabled) {
        zoneDelegate.print(parent, line);
      }
    } finally {
      _isHandlingPrint = false;
    }
  }

  bool _containsAnsi(String line) => line.contains(_ansiPattern);

  _ErrorSnapshot _captureStrings(Object? exception, StackTrace? stack) {
    final message = exception?.toString() ?? '';
    final stackStr = stack?.toString() ?? '';
    return _ErrorSnapshot(message, stackStr);
  }
}

class _ErrorSnapshot {
  const _ErrorSnapshot(this.message, this.stack);

  final String message;
  final String stack;
}
