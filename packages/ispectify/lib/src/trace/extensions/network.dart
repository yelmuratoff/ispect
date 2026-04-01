import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerNetwork on ISpectLogger {
  void httpRequest({
    required String source,
    required String operation,
    String? target,
    String? correlationId,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
  }) {
    if (!options.enabled) return;
    trace(
      category: networkCategory,
      source: source,
      operation: operation,
      target: target,
      logKey: ISpectLogType.httpRequest.key,
      success: true,
      correlationId: correlationId,
      config: config,
      meta: meta,
    );
  }

  void httpResponse({
    required String source,
    required String operation,
    String? target,
    Duration? duration,
    String? correlationId,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
  }) {
    if (!options.enabled) return;
    trace(
      category: networkCategory,
      source: source,
      operation: operation,
      target: target,
      logKey: ISpectLogType.httpResponse.key,
      success: true,
      duration: duration,
      correlationId: correlationId,
      config: config,
      meta: meta,
    );
  }

  void httpError({
    required String source,
    required String operation,
    String? target,
    Object? error,
    StackTrace? errorStackTrace,
    Duration? duration,
    String? correlationId,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
  }) {
    if (!options.enabled) return;
    trace(
      category: networkCategory,
      source: source,
      operation: operation,
      target: target,
      logKey: ISpectLogType.httpError.key,
      success: false,
      error: error,
      errorStackTrace: errorStackTrace,
      duration: duration,
      correlationId: correlationId,
      config: config,
      meta: meta,
    );
  }
}
