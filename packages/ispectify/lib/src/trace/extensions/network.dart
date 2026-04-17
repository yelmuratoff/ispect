import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for raw HTTP request / response / error events.
///
/// These are typically emitted by interceptor packages (ispectify_dio,
/// ispectify_http) — call them directly only when instrumenting a custom HTTP
/// client.
extension ISpectLoggerNetwork on ISpectLogger {
  /// Logs an outgoing HTTP request under [networkCategory].
  void httpRequest({
    required String source,
    required String operation,
    String? target,
    String? correlationId,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: networkCategory,
        source: source,
        operation: operation,
        target: target,
        logKey: ISpectLogType.httpRequest.key,
        success: true,
        correlationId: correlationId,
        config: config,
        meta: meta,
        consoleMessage: consoleMessage,
      );

  /// Logs an HTTP response (2xx/3xx) under [networkCategory].
  void httpResponse({
    required String source,
    required String operation,
    String? target,
    Duration? duration,
    String? correlationId,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
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
        consoleMessage: consoleMessage,
      );

  /// Logs an HTTP error (4xx/5xx or transport failure) under [networkCategory].
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
    String? consoleMessage,
  }) =>
      traceCategory(
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
        consoleMessage: consoleMessage,
      );
}
