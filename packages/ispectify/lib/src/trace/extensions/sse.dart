import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';
import 'package:ispectify/src/trace/trace_helpers.dart';

/// Trace helpers for Server-Sent Events (SSE) streams.
extension ISpectLoggerSSE on ISpectLogger {
  /// Logs an SSE event under [sseCategory].
  ///
  /// Success is inferred from [error] being `null`.
  void sse({
    required String source,
    required String operation,
    String? url,
    String? eventType,
    String? eventId,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? data,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!isEnabled) return;
    traceCategory(
      category: sseCategory,
      source: source,
      operation: operation,
      target: url,
      key: eventId,
      error: error,
      errorStackTrace: errorStackTrace,
      success: error == null,
      meta: boundedTraceMeta(
        fields: {
          if (eventType != null) 'eventType': eventType,
          if (data != null) 'data': data,
        },
        overrides: meta,
      ),
      correlationId: correlationId,
      config: config,
    );
  }
}
