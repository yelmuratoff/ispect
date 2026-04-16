import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerWs on ISpectLogger {
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
}
