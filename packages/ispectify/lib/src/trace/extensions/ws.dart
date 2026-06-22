import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for WebSocket send / receive events.
extension ISpectLoggerWs on ISpectLogger {
  /// Logs an outbound WebSocket message under [wsCategory].
  void wsSend({
    required String source,
    required String operation,
    String? target,
    String? eventType,
    int? sizeBytes,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: wsCategory,
        source: source,
        operation: operation,
        target: target,
        success: error == null,
        error: error,
        errorStackTrace: errorStackTrace,
        meta: {
          if (eventType != null) 'eventType': eventType,
          if (sizeBytes != null) 'sizeBytes': sizeBytes,
          ...?meta,
        },
        config: config,
        correlationId: correlationId,
        consoleMessage: consoleMessage,
      );

  /// Logs an inbound WebSocket message under [wsCategory].
  void wsReceive({
    required String source,
    required String operation,
    String? target,
    String? eventType,
    int? sizeBytes,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: wsCategory,
        source: source,
        operation: operation,
        target: target,
        success: error == null,
        error: error,
        errorStackTrace: errorStackTrace,
        meta: {
          if (eventType != null) 'eventType': eventType,
          if (sizeBytes != null) 'sizeBytes': sizeBytes,
          ...?meta,
        },
        config: config,
        correlationId: correlationId,
        consoleMessage: consoleMessage,
      );

  /// Logs a WebSocket connection-state change under [wsCategory].
  ///
  /// Emits with an explicit `ws-state` key, bypassing the category's
  /// success/error key-picker: a connection-lifecycle event is neither the
  /// success nor the error of a request/response, so it carries its own key.
  void wsState({
    required String source,
    required String state,
    String? target,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: wsCategory,
        source: source,
        operation: 'state',
        target: target,
        logKey: ISpectLogType.wsState.key,
        success: true,
        meta: {
          'state': state,
          ...?meta,
        },
        config: config,
        correlationId: correlationId,
        consoleMessage: consoleMessage,
      );
}
