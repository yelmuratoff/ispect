import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerStorage on ISpectLogger {
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
  }) {
    if (!options.enabled) return run();
    return traceAsync(
      category: storageCategory,
      source: source,
      operation: operation,
      target: path,
      config: config,
      correlationId: correlationId,
      meta: {
        if (bucket != null) 'bucket': bucket,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        if (contentType != null) 'contentType': contentType,
        ...?meta,
      },
      run: run,
      projectResult: projectResult,
    );
  }

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
  }) {
    if (!options.enabled) return;
    trace(
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
}
