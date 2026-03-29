import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerSSE on ISpectLogger {
  void sse({
    required String source,
    required String operation,
    String? url,
    String? eventType,
    String? eventId,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? data,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;
    trace(
      category: sseCategory,
      source: source,
      operation: operation,
      target: url,
      key: eventId,
      error: error,
      errorStackTrace: errorStackTrace,
      success: error == null,
      meta: {
        if (eventType != null) 'eventType': eventType,
        if (data != null) 'data': data,
      },
      correlationId: correlationId,
      config: config,
    );
  }
}
