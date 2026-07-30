import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/services/error_handler_options.dart';
import 'package:ispectify/ispectify.dart';

/// Installs and owns the app-level error/log handlers (`FlutterError`,
/// `PlatformDispatcher`, guarded-zone, and `print`) and funnels every captured
/// failure through [ISpectLogger.handle]. Host callbacks keep the original
/// errors and stacks so application recovery and crash reporting still work.
final class ErrorHandlerService {
  ErrorHandlerService({
    required this.logger,
    required this.filters,
  });

  final ISpectLogger logger;
  final List<String> filters;

  bool _isHandlingPrint = false;
  bool _isDisposed = false;
  late FlutterExceptionHandler _previousPresentError;
  FlutterExceptionHandler? _installedPresentError;
  FlutterExceptionHandler? _previousFlutterError;
  FlutterExceptionHandler? _installedFlutterError;
  _PlatformErrorHandler? _previousPlatformError;
  _PlatformErrorHandler? _installedPlatformError;

  void setupErrorHandling({
    required ISpectErrorHandlerOptions options,
    void Function(Object, StackTrace)? onPlatformDispatcherError,
    void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    void Function(FlutterErrorDetails, StackTrace?)? onPresentError,
    void Function(Object error, StackTrace? stack)? onUncaughtError,
  }) {
    if (_isDisposed) {
      throw StateError('Cannot configure a disposed ErrorHandlerService.');
    }
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
    final previous = FlutterError.presentError;
    late final FlutterExceptionHandler installed;
    installed = (details) {
      if (_isDisposed) {
        previous(details);
        return;
      }

      void report() {
        if (_isDisposed) {
          previous(details);
          return;
        }
        final snapshot = _captureDiagnostic(details.exception, details.stack);
        onPresentError?.call(details, details.stack);
        _report(
          snapshot: snapshot,
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
    _previousPresentError = previous;
    _installedPresentError = installed;
    FlutterError.presentError = installed;
  }

  void _setupPlatformDispatcherHandler({
    required void Function(Object, StackTrace)? onPlatformDispatcherError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    final previous = PlatformDispatcher.instance.onError;
    late final _PlatformErrorHandler installed;
    installed = (error, stack) {
      if (_isDisposed) {
        return previous?.call(error, stack) ?? false;
      }
      final snapshot = _captureDiagnostic(error, stack);
      onPlatformDispatcherError?.call(error, stack);
      _report(
        snapshot: snapshot,
        logMessage: 'Platform error caught',
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
      );
      return true;
    };
    _previousPlatformError = previous;
    _installedPlatformError = installed;
    PlatformDispatcher.instance.onError = installed;
  }

  void _setupFlutterErrorHandler({
    required void Function(FlutterErrorDetails, StackTrace?)? onFlutterError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    final previous = FlutterError.onError;
    late final FlutterExceptionHandler installed;
    installed = (details) {
      if (_isDisposed) {
        previous?.call(details);
        return;
      }
      final snapshot = _captureDiagnostic(details.exception, details.stack);
      onFlutterError?.call(details, details.stack);
      _report(
        snapshot: snapshot,
        logMessage: 'Flutter error caught',
        onUncaughtError: onUncaughtError,
        isUncaughtErrorsHandlingEnabled: isUncaughtErrorsHandlingEnabled,
      );
    };
    _previousFlutterError = previous;
    _installedFlutterError = installed;
    FlutterError.onError = installed;
  }

  void handleZoneError(
    Object error,
    StackTrace stackTrace, {
    required void Function(Object, StackTrace)? onZonedError,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    final snapshot = _captureDiagnostic(error, stackTrace);
    onZonedError?.call(error, stackTrace);
    _report(
      snapshot: snapshot,
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
        logger.print(_sanitizeText(line));
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
    required _DiagnosticSnapshot snapshot,
    required String logMessage,
    required void Function(Object error, StackTrace? stack)? onUncaughtError,
    required bool isUncaughtErrorsHandlingEnabled,
  }) {
    if (!_shouldHandleError(snapshot)) return;

    logger.handle(
      message: _sanitizeText(logMessage),
      exception: snapshot.exception,
      stackTrace: snapshot.stack,
    );

    if (isUncaughtErrorsHandlingEnabled) {
      onUncaughtError?.call(snapshot.exception, snapshot.stack);
    }
  }

  bool _shouldHandleError(_DiagnosticSnapshot snapshot) {
    if (filters.isEmpty) return true;

    return !filters.any(
      (filter) =>
          snapshot.filterExceptionText.contains(filter) ||
          snapshot.filterStackText.contains(filter),
    );
  }

  Object? _prepareDiagnosticValue(
    Object value, {
    required bool replaceOversizedStrings,
  }) {
    try {
      return LogExportOutput.boundJsonValue(
        value,
        resourceLimits: logger.options.resourceLimits,
        replaceOversizedStrings: replaceOversizedStrings,
      );
    } on Object {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  _DiagnosticSnapshot _captureDiagnostic(
    Object exception,
    StackTrace? stack,
  ) {
    final redactionActive = ISpectRedaction.enabled;
    final preparedException = _prepareDiagnosticValue(
      exception,
      replaceOversizedStrings: redactionActive,
    );
    final preparedStack = stack == null
        ? null
        : _prepareDiagnosticValue(
            stack,
            replaceOversizedStrings: redactionActive,
          );
    final filterExceptionText = _diagnosticSnapshotText(preparedException);
    final filterStackText =
        preparedStack == null ? '' : _diagnosticSnapshotText(preparedStack);
    return _DiagnosticSnapshot(
      filterExceptionText: filterExceptionText,
      filterStackText: filterStackText,
      exception: exception,
      stack: stack,
    );
  }

  String _sanitizeText(String value) => _safeDiagnosticText(value);

  String _safeDiagnosticText(Object value) {
    final redactionActive = ISpectRedaction.enabled;
    final prepared = _prepareDiagnosticValue(
      value,
      replaceOversizedStrings: redactionActive,
    );
    return redactionActive
        ? _redactPreparedDiagnostic(prepared)
        : _diagnosticSnapshotText(prepared);
  }

  String _redactPreparedDiagnostic(Object? prepared) {
    try {
      final redacted = ISpectRedaction.service.redactForExport(
        prepared,
        resourceLimits: logger.options.resourceLimits,
      );
      final bounded = LogExportOutput.boundJsonValue(
        redacted,
        resourceLimits: logger.options.resourceLimits,
        replaceOversizedStrings: true,
      );
      return _diagnosticSnapshotText(bounded);
    } on Object {
      return defaultPlaceholder;
    }
  }

  String _diagnosticSnapshotText(Object? value) {
    if (value == null) return defaultPlaceholder;

    final String text;
    if (value is String) {
      text = value;
    } else if (value is bool || value is num) {
      text = value.toString();
    } else {
      try {
        text = jsonEncode(value);
      } on Object {
        return defaultPlaceholder;
      }
    }
    return LogExportOutput.truncateUtf8(
      text,
      maxBytes: logger.options.resourceLimits.maxUiDiagnosticBytes,
    );
  }

  /// Restores every host handler that this service still owns.
  ///
  /// Identity checks avoid clobbering handlers installed by the application or
  /// another diagnostics library after ISpect was initialized.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    final installedPresentError = _installedPresentError;
    if (installedPresentError != null &&
        identical(FlutterError.presentError, installedPresentError)) {
      FlutterError.presentError = _previousPresentError;
    }

    final installedFlutterError = _installedFlutterError;
    if (installedFlutterError != null &&
        identical(FlutterError.onError, installedFlutterError)) {
      FlutterError.onError = _previousFlutterError;
    }

    final installedPlatformError = _installedPlatformError;
    if (installedPlatformError != null &&
        identical(
          PlatformDispatcher.instance.onError,
          installedPlatformError,
        )) {
      PlatformDispatcher.instance.onError = _previousPlatformError;
    }
  }
}

typedef _PlatformErrorHandler = bool Function(Object, StackTrace);

final class _DiagnosticSnapshot {
  const _DiagnosticSnapshot({
    required this.filterExceptionText,
    required this.filterStackText,
    required this.exception,
    required this.stack,
  });

  final String filterExceptionText;
  final String filterStackText;
  final Object exception;
  final StackTrace? stack;
}
