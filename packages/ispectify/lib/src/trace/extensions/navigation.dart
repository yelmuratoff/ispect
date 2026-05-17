import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for Navigator / router transitions.
extension ISpectLoggerNavigation on ISpectLogger {
  /// Logs a navigation event under [navigationCategory].
  ///
  /// [operation] is typically `"push"` / `"pop"` / `"replace"`.
  /// [routeName] becomes the log target; [fromRoute] and [arguments] go to meta.
  void navigationTrace({
    required String source,
    required String operation,
    required String routeName,
    String? fromRoute,
    Object? arguments,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategory(
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
