import 'dart:async';

import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/trace/trace_category.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_helpers.dart';
import 'package:ispectify/src/trace/trace_keys.dart';
import 'package:ispectify/src/trace/trace_message.dart';
import 'package:ispectify/src/trace/trace_stream_transformer.dart';
import 'package:ispectify/src/trace/trace_token.dart';
import 'package:ispectify/src/utils/common_utils.dart';

/// File-private zone key — prevents external code from reading/spoofing txnId.
final _txnZoneKey = Object();

extension ISpectTrace on ISpectLogger {
  // ── Domain-extension shortcuts ──────────────────────────────────────
  //
  // These wrap [trace] / [traceAsync] with the enabled-check so that
  // domain extensions (auth, storage, push …) don't repeat the guard.

  /// Convenience wrapper: checks `options.enabled`, then delegates to [trace].
  void traceCategory({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Duration? duration,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? logKey,
    String? correlationId,
    String? consoleMessage,
  }) {
    if (!options.enabled) return;
    trace(
      category: category,
      source: source,
      operation: operation,
      target: target,
      key: key,
      success: success,
      error: error,
      errorStackTrace: errorStackTrace,
      duration: duration,
      meta: meta,
      config: config,
      logKey: logKey,
      correlationId: correlationId,
      consoleMessage: consoleMessage,
    );
  }

  /// Convenience wrapper: checks `options.enabled`, then delegates to
  /// [traceAsync].
  Future<T> traceCategoryAsync<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? target,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();
    return traceAsync(
      category: category,
      source: source,
      operation: operation,
      target: target,
      meta: meta,
      run: run,
      projectResult: projectResult,
      config: config,
      correlationId: correlationId,
    );
  }

  // ── Fire-and-forget ─────────────────────────────────────────────────

  void trace({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    Object? value,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Duration? duration,
    Map<String, Object?>? meta,
    double? sample,
    ISpectTraceConfig? config,
    String? logKey,
    String? correlationId,
    LogLevel? logLevel,
    String? consoleMessage,
  }) {
    if (!options.enabled) return;

    final cfg = config ?? const ISpectTraceConfig();
    final isError = error != null || success == false;

    if (!cfg.shouldLog(localSample: sample, isError: isError)) return;

    final resolvedLogKey =
        logKey ?? category.pickLogKey(isError: isError, operation: operation);

    safeTrace(this, () {
      final safeTarget = cfg.redact && target != null
          ? RedactionService.redactTarget(target, cfg.redactKeys)
          : target;

      final message = consoleMessage ??
          buildTraceMessage(
            source: source,
            operation: operation,
            target: safeTarget,
            key: key,
            duration: duration,
            success: !isError,
          );

      final safeMeta = cfg.redact
          ? RedactionService.redactByKeys(meta, cfg.redactKeys)
          : meta;

      final rawTxnId = Zone.current[_txnZoneKey];
      final zoneTxnId = rawTxnId is String ? rawTxnId : null;

      final additionalData = <String, Object?>{
        TraceKeys.category: category.id,
        TraceKeys.source: source,
        TraceKeys.operation: operation,
        if (safeTarget != null) TraceKeys.target: safeTarget,
        if (key != null) TraceKeys.key: key,
        if (value != null)
          TraceKeys.value: truncateValue(value, cfg.maxValueLength),
        if (duration != null) TraceKeys.durationMs: duration.inMilliseconds,
        if (duration != null && cfg.slowThreshold != null)
          TraceKeys.slow: duration > cfg.slowThreshold!,
        TraceKeys.success: !isError,
        if (error != null) TraceKeys.error: '$error',
        if (zoneTxnId != null) TraceKeys.transactionId: zoneTxnId,
        if (correlationId != null) TraceKeys.correlationId: correlationId,
        if (safeMeta != null) TraceKeys.meta: safeMeta,
      };

      return ISpectLogData(
        message,
        key: resolvedLogKey,
        logLevel: logLevel ?? (isError ? LogLevel.error : LogLevel.info),
        additionalData: additionalData,
        exception: error is Exception ? error : null,
        error: error is Error ? error : null,
        stackTrace: isError && cfg.attachStackOnError ? errorStackTrace : null,
      );
    });
  }

  // ── Async wrapper with auto-timing ──────────────────────────────────

  Future<T> traceAsync<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectResult,
    double? sample,
    ISpectTraceConfig? config,
    String? logKey,
    LogLevel? logLevel,
    String? correlationId,
  }) async {
    if (!options.enabled) return run();

    final sw = Stopwatch()..start();
    try {
      final result = await run();
      sw.stop();

      Object? projected;
      if (projectResult != null) {
        try {
          projected = projectResult(result);
        } catch (e, st) {
          handle(exception: e, stackTrace: st);
        }
      }

      trace(
        category: category,
        source: source,
        operation: operation,
        target: target,
        key: key,
        value: projected,
        success: true,
        duration: sw.elapsed,
        meta: meta,
        config: config,
        sample: sample,
        logKey: logKey,
        correlationId: correlationId,
        logLevel: logLevel,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category,
        source: source,
        operation: operation,
        target: target,
        key: key,
        error: e,
        errorStackTrace: st,
        success: false,
        duration: sw.elapsed,
        meta: meta,
        config: config,
        sample: sample,
        logKey: logKey,
        correlationId: correlationId,
        logLevel: logLevel,
      );
      rethrow;
    }
  }

  // ── Sync wrapper ────────────────────────────────────────────────────

  T traceSync<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required T Function() run,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectResult,
    double? sample,
    ISpectTraceConfig? config,
    String? logKey,
    String? correlationId,
    LogLevel? logLevel,
  }) {
    if (!options.enabled) return run();

    final sw = Stopwatch()..start();
    try {
      final result = run();
      sw.stop();

      Object? projected;
      if (projectResult != null) {
        try {
          projected = projectResult(result);
        } catch (e, st) {
          log(
            'traceSync: projectResult threw unexpectedly — $e',
            logLevel: LogLevel.warning,
            stackTrace: st,
          );
        }
      }

      trace(
        category: category,
        source: source,
        operation: operation,
        target: target,
        key: key,
        value: projected,
        success: true,
        duration: sw.elapsed,
        meta: meta,
        config: config,
        sample: sample,
        logKey: logKey,
        correlationId: correlationId,
        logLevel: logLevel,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category,
        source: source,
        operation: operation,
        target: target,
        key: key,
        error: e,
        errorStackTrace: st,
        success: false,
        duration: sw.elapsed,
        meta: meta,
        config: config,
        sample: sample,
        logKey: logKey,
        correlationId: correlationId,
        logLevel: logLevel,
      );
      rethrow;
    }
  }

  // ── Manual span (request → response) ────────────────────────────────

  /// Returns `null` if logger is disabled — caller must check.
  ISpectTraceToken? traceStart({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return null;
    return ISpectTraceToken(
      stopwatch: Stopwatch()..start(),
      category: category,
      source: source,
      operation: operation,
      target: target,
      key: key,
      meta: meta,
      config: config,
      correlationId: correlationId,
    );
  }

  /// Ends a manual span. [token] is nullable — if [traceStart] returned null
  /// (logger disabled), this is a no-op.
  void traceEnd(
    ISpectTraceToken? token, {
    Object? value,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
  }) {
    if (token == null) return;
    token.stopTiming();
    trace(
      category: token.category,
      source: token.source,
      operation: token.operation,
      target: token.target,
      key: token.key,
      value: value,
      success: success ?? (error == null),
      error: error,
      errorStackTrace: errorStackTrace,
      duration: token.elapsed,
      meta: {...?token.meta, ...?meta},
      config: token.config,
      correlationId: token.correlationId,
    );
  }

  // ── Stream tracing ──────────────────────────────────────────────────

  Stream<T> traceStream<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required Stream<T> stream,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectEvent,
    double? sample,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return stream;

    final corrId = correlationId ?? generateTraceId();

    return stream.transform(
      TraceStreamTransformer<T>(
        onListen: () => trace(
          category: category,
          source: source,
          operation: '$operation.subscribe',
          target: target,
          success: true,
          config: config,
          correlationId: corrId,
        ),
        onData: (data) {
          Object? projected;
          if (projectEvent != null) {
            try {
              projected = projectEvent(data);
            } catch (_) {}
          }
          trace(
            category: category,
            source: source,
            operation: '$operation.event',
            target: target,
            value: projected,
            success: true,
            sample: sample,
            config: config,
            correlationId: corrId,
          );
        },
        onError: (e, st) => trace(
          category: category,
          source: source,
          operation: '$operation.error',
          target: target,
          error: e,
          errorStackTrace: st,
          success: false,
          config: config,
          correlationId: corrId,
        ),
        onCancel: () => trace(
          category: category,
          source: source,
          operation: '$operation.unsubscribe',
          target: target,
          success: true,
          config: config,
          correlationId: corrId,
        ),
      ),
    );
  }

  // ── Transaction (zone-based ID) ─────────────────────────────────────

  /// Runs [run] inside a zone with auto-injected transaction ID.
  ///
  /// All [trace] calls within [run] will automatically include the
  /// transaction ID in [TraceKeys.transactionId].
  ///
  /// NB: Zone values do NOT cross isolate boundaries.
  Future<T> traceTransaction<T>({
    required ISpectTraceCategory category,
    required String source,
    required Future<T> Function() run,
    bool logMarkers = false,
  }) async {
    final txnId = generateTraceId();
    return runZoned(
      () async {
        if (logMarkers) {
          trace(
            category: category,
            source: source,
            operation: 'transaction-begin',
            success: true,
          );
        }
        try {
          final result = await run();
          if (logMarkers) {
            trace(
              category: category,
              source: source,
              operation: 'transaction-commit',
              success: true,
            );
          }
          return result;
        } catch (e, st) {
          if (logMarkers) {
            trace(
              category: category,
              source: source,
              operation: 'transaction-rollback',
              error: e,
              errorStackTrace: st,
              success: false,
            );
          }
          rethrow;
        }
      },
      zoneValues: {_txnZoneKey: txnId},
    );
  }
}
