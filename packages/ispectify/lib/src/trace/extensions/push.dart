import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerPush on ISpectLogger {
  void push({
    required String source,
    required String operation,
    String? title,
    String? topic,
    String? messageId,
    Map<String, Object?>? data,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;
    trace(
      category: pushCategory,
      source: source,
      operation: operation,
      key: messageId,
      meta: {
        if (title != null) 'title': title,
        if (topic != null) 'topic': topic,
        if (data != null) 'data': data,
        ...?meta,
      },
      config: config,
      // Auto-correlation: use messageId if correlationId not provided.
      correlationId: correlationId ?? messageId,
    );
  }
}
