import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerState on ISpectLogger {
  Future<T> stateTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? stateName,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) =>
      traceCategoryAsync(
        category: stateCategory,
        source: source,
        operation: operation,
        target: stateName,
        meta: meta,
        run: run,
        projectResult: projectResult,
        config: config,
        correlationId: correlationId,
      );

  void stateChange({
    required String source,
    required String operation,
    String? stateName,
    bool? success,
    Object? fromState,
    Object? toState,
    String? event,
    Object? error,
    StackTrace? errorStackTrace,
    Duration? duration,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: operation,
        target: stateName,
        success: success ?? (error == null),
        error: error,
        errorStackTrace: errorStackTrace,
        duration: duration,
        meta: {
          if (fromState != null) 'from': '$fromState',
          if (toState != null) 'to': '$toState',
          if (event != null) 'event': event,
          ...?meta,
        },
        config: config,
        correlationId: correlationId,
        consoleMessage: consoleMessage,
      );
}
