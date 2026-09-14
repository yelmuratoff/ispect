import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';
import 'package:ispectify/src/trace/trace_helpers.dart';

/// Trace helpers for push / remote notifications.
extension ISpectLoggerPush on ISpectLogger {
  /// Logs a push notification event under [pushCategory].
  ///
  /// When [correlationId] is omitted, [messageId] is used as the correlation
  /// id so send and receive events on the same message line up.
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
    if (!isEnabled) return;
    traceCategory(
      category: pushCategory,
      source: source,
      operation: operation,
      key: messageId,
      meta: boundedTraceMeta(
        fields: {
          if (title != null) 'title': title,
          if (topic != null) 'topic': topic,
          if (data != null) 'data': data,
        },
        overrides: meta,
      ),
      config: config,
      correlationId: correlationId ?? messageId,
    );
  }
}
