import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for BLoC / Cubit lifecycle events.
///
/// These are typically emitted by the `ispectify_bloc` observer — call them
/// directly only when instrumenting a custom `BlocObserver`.
extension ISpectLoggerBloc on ISpectLogger {
  /// Logs `onEvent` under [stateCategory] with the `bloc-event` key.
  void blocEvent({
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
        operation: 'event',
        target: target,
        logKey: ISpectLogType.blocEvent.key,
        success: true,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `onTransition` under [stateCategory] with the `bloc-transition` key.
  void blocTransition({
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
        operation: 'transition',
        target: target,
        logKey: ISpectLogType.blocTransition.key,
        success: true,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `onChange` under [stateCategory] with the `bloc-state` key.
  void blocState({
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
        operation: 'state',
        target: target,
        logKey: ISpectLogType.blocState.key,
        success: true,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `onCreate` under [stateCategory] with the `bloc-create` key.
  void blocCreate({
    required String source,
    required String target,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'create',
        target: target,
        logKey: ISpectLogType.blocCreate.key,
        success: true,
        meta: meta,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `onClose` under [stateCategory] with the `bloc-close` key.
  void blocClose({
    required String source,
    required String target,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'close',
        target: target,
        logKey: ISpectLogType.blocClose.key,
        success: true,
        meta: meta,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `onDone` under [stateCategory] with the `bloc-done` key.
  ///
  /// When [error] is non-null, the trace entry carries the failure but keeps
  /// the `bloc-done` key so `byOperation('done')` filters remain stable.
  void blocDone({
    required String source,
    required String target,
    bool hasError = false,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
    String? correlationId,
    ISpectTraceConfig? config,
    String? consoleMessage,
  }) =>
      traceCategory(
        category: stateCategory,
        source: source,
        operation: 'done',
        target: target,
        logKey: ISpectLogType.blocDone.key,
        success: !hasError,
        error: error,
        errorStackTrace: errorStackTrace,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );

  /// Logs `onError` under [stateCategory] with the `bloc-error` key.
  void blocError({
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
        operation: 'error',
        target: target,
        logKey: ISpectLogType.blocError.key,
        success: false,
        error: error,
        errorStackTrace: errorStackTrace,
        meta: meta,
        correlationId: correlationId,
        config: config,
        consoleMessage: consoleMessage,
      );
}
