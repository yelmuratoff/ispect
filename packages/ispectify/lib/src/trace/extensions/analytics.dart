import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for analytics events (screen views, product impressions, etc.).
extension ISpectLoggerAnalytics on ISpectLogger {
  /// Logs an analytics event under [analyticsCategory].
  ///
  /// [event] is the event name (e.g. `"screen_view"`, `"purchase"`).
  /// [parameters] are passed as meta.
  void analyticsEvent({
    required String source,
    required String event,
    Map<String, Object?>? parameters,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategory(
        category: analyticsCategory,
        source: source,
        operation: event,
        meta: parameters,
        success: true,
        config: config,
        correlationId: correlationId,
      );
}
