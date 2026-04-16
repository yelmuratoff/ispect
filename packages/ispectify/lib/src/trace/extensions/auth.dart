import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerAuth on ISpectLogger {
  Future<T> authTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? userId,
    String? provider,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategoryAsync(
        category: authCategory,
        source: source,
        operation: operation,
        meta: {
          if (userId != null) 'userId': userId,
          if (provider != null) 'provider': provider,
          ...?meta,
        },
        run: run,
        projectResult: projectResult,
        config: config,
        correlationId: correlationId,
      );

  void auth({
    required String source,
    required String operation,
    String? userId,
    String? provider,
    bool? success,
    Object? error,
    Duration? duration,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategory(
        category: authCategory,
        source: source,
        operation: operation,
        success: success,
        error: error,
        duration: duration,
        meta: {
          if (userId != null) 'userId': userId,
          if (provider != null) 'provider': provider,
          ...?meta,
        },
        config: config,
        correlationId: correlationId,
      );
}
