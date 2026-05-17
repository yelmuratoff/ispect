import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for payment and in-app purchase flows.
extension ISpectLoggerPayment on ISpectLogger {
  /// Traces an async payment operation under [paymentCategory].
  ///
  /// [productId] becomes the log target; [amount] and [currency] go to meta.
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
  }) =>
      traceCategoryAsync(
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
