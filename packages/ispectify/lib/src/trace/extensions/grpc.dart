import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerGrpc on ISpectLogger {
  /// For unary and server-streaming gRPC calls.
  /// For client-streaming / bidi-streaming, use `traceStream()` directly.
  Future<T> grpcTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? service,
    String? method,
    Map<String, Object?>? grpcMetadata,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();
    return traceAsync(
      category: grpcCategory,
      source: source,
      operation: operation,
      target: service != null && method != null ? '$service/$method' : null,
      meta: {
        if (service != null) 'service': service,
        if (method != null) 'method': method,
        if (grpcMetadata != null) 'grpcMetadata': grpcMetadata,
      },
      run: run,
      projectResult: projectResult,
      config: config,
      correlationId: correlationId,
    );
  }
}
