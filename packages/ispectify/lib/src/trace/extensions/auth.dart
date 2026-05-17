import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for authentication flows (sign-in, sign-out, refresh, etc.).
extension ISpectLoggerAuth on ISpectLogger {
  /// Traces an async auth operation under [authCategory].
  ///
  /// Awaits [run], records duration, and logs success or failure with
  /// `userId`/`provider` captured in meta.
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

  /// Logs a one-shot auth event without awaiting a future.
  ///
  /// Use when the operation isn't structured as a `Future` (e.g. logging an
  /// already-completed result, emitting a breadcrumb, or recording failure
  /// from a callback).
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
