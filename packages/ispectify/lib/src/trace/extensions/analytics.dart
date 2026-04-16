import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerAnalytics on ISpectLogger {
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
