import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerNavigation on ISpectLogger {
  void navigationTrace({
    required String source,
    required String operation,
    required String routeName,
    String? fromRoute,
    Object? arguments,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;
    trace(
      category: navigationCategory,
      source: source,
      operation: operation,
      target: routeName,
      success: true,
      meta: {
        if (fromRoute != null) 'from': fromRoute,
        if (arguments != null) 'arguments': '$arguments',
        ...?meta,
      },
      config: config,
      correlationId: correlationId,
    );
  }
}
