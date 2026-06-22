import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for Riverpod provider lifecycle events.
///
/// These are typically emitted by the `ispectify_riverpod` observer — call
/// them directly only when instrumenting a custom `ProviderObserver`.
extension ISpectLoggerRiverpod on ISpectLogger {
  /// Logs `didAddProvider` under [stateCategory] with the `riverpod-add` key.
  void riverpodAdd({
    required String source,
    required String target,
    Map<String, Object?>? meta,
    String? correlationId,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'add',
        target: target,
        logKey: ISpectLogType.riverpodAdd.key,
        success: true,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `didUpdateProvider` under [stateCategory] with the `riverpod-update`
  /// key.
  void riverpodUpdate({
    required String source,
    required String target,
    Map<String, Object?>? meta,
    String? correlationId,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'update',
        target: target,
        logKey: ISpectLogType.riverpodUpdate.key,
        success: true,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `didDisposeProvider` under [stateCategory] with the
  /// `riverpod-dispose` key.
  void riverpodDispose({
    required String source,
    required String target,
    Map<String, Object?>? meta,
    String? correlationId,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'dispose',
        target: target,
        logKey: ISpectLogType.riverpodDispose.key,
        success: true,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `providerDidFail` under [stateCategory] with the `riverpod-fail` key.
  void riverpodFail({
    required String source,
    required String target,
    required Object error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
    String? correlationId,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'fail',
        target: target,
        logKey: ISpectLogType.riverpodFail.key,
        success: false,
        error: error,
        errorStackTrace: errorStackTrace,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );
}
