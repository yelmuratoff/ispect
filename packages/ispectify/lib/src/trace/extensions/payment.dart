import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

extension ISpectLoggerPayment on ISpectLogger {
  Future<T> paymentTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? productId,
    double? amount,
    String? currency,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();
    return traceAsync(
      category: paymentCategory,
      source: source,
      operation: operation,
      target: productId,
      meta: {
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
        ...?meta,
      },
      run: run,
      projectResult: projectResult,
      config: config,
      correlationId: correlationId,
    );
  }
}
