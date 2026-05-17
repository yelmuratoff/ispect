import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for object-storage / file-storage operations
/// (S3, Firebase Storage, local fs, etc.).
extension ISpectLoggerStorage on ISpectLogger {
  /// Traces an async storage operation under [storageCategory].
  ///
  /// [path] becomes the log target; [bucket], [sizeBytes], and [contentType]
  /// are stored in meta.
  Future<T> storageTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? bucket,
    String? path,
    int? sizeBytes,
    String? contentType,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategoryAsync(
        category: storageCategory,
        source: source,
        operation: operation,
        target: path,
        meta: {
          if (bucket != null) 'bucket': bucket,
          if (sizeBytes != null) 'sizeBytes': sizeBytes,
          if (contentType != null) 'contentType': contentType,
          ...?meta,
        },
        run: run,
        projectResult: projectResult,
        config: config,
        correlationId: correlationId,
      );

  /// Logs a one-shot storage event without awaiting a future.
  void storage({
    required String source,
    required String operation,
    String? bucket,
    String? path,
    int? sizeBytes,
    String? contentType,
    bool? success,
    Object? error,
    Duration? duration,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategory(
        category: storageCategory,
        source: source,
        operation: operation,
        target: path,
        success: success,
        error: error,
        duration: duration,
        meta: {
          if (bucket != null) 'bucket': bucket,
          if (sizeBytes != null) 'sizeBytes': sizeBytes,
          if (contentType != null) 'contentType': contentType,
          ...?meta,
        },
        config: config,
        correlationId: correlationId,
      );
}
