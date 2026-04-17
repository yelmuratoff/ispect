import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';
import 'package:ispectify/src/trace/trace_helpers.dart';

/// Trace helpers for GraphQL queries, mutations, and subscriptions.
extension ISpectLoggerGraphQL on ISpectLogger {
  /// Traces an async GraphQL operation under [graphqlCategory].
  ///
  /// Captures [operationName], [document] (truncated per config), and
  /// [variables] in meta; awaits [run] and records duration / result.
  Future<T> graphqlTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? operationName,
    String? document,
    Map<String, Object?>? variables,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    final cfg = config ?? const ISpectTraceConfig();
    return traceCategoryAsync(
      category: graphqlCategory,
      source: source,
      operation: operation,
      target: operationName,
      meta: {
        if (document != null)
          'document': truncateValue(document, cfg.maxValueLength) ?? '',
        if (variables != null) 'variables': variables,
      },
      run: run,
      projectResult: projectResult,
      config: cfg,
      correlationId: correlationId,
    );
  }
}
