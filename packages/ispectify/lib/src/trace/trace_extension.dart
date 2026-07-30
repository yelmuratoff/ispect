import 'dart:async';
import 'dart:convert';

import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/redaction/redaction_toggle.dart';
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

  /// Convenience wrapper: checks [ISpectLogger.isEnabled], then delegates to
  /// [trace].
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
    if (!isEnabled) return;
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

  /// Convenience wrapper: checks [ISpectLogger.isEnabled], then delegates to
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
    if (!isEnabled) return run();
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
    if (!isEnabled) return;

    final cfg = config ?? const ISpectTraceConfig();
    final resourceLimits = (cfg.resourceLimits ?? options.resourceLimits)
      ..validate();
    final isError = error != null || success == false;

    if (!cfg.shouldLog(localSample: sample, isError: isError)) return;

    final resolvedLogKey =
        logKey ?? category.pickLogKey(isError: isError, operation: operation);

    safeTrace(
      this,
      () {
        final redactor = _traceRedactor(cfg);
        final captureMode = options.captureMode;
        String prepareText(Object? value) => _tracePayloadText(
              _prepareTracePayload(
                value,
                redactor,
                captureMode,
                resourceLimits,
              ),
              resourceLimits,
            );

        final safeCategoryId = prepareText(category.id);
        final safeSource = prepareText(source);
        final safeOperation = prepareText(operation);
        final safeTarget = target == null ? null : prepareText(target);
        final safeKey = key == null ? null : prepareText(key);
        final safeLogKey = prepareText(resolvedLogKey);

        final rawMessage = consoleMessage ??
            buildTraceMessage(
              operation: safeOperation,
              source: safeSource,
              target: safeTarget,
              key: safeKey,
              duration: duration,
              success: !isError,
            );
        final message = prepareText(rawMessage);

        final safeMetaValue = _prepareTracePayload(
          meta,
          redactor,
          captureMode,
          resourceLimits,
        );
        final safeMeta = safeMetaValue is Map<String, Object?>
            ? safeMetaValue
            : safeMetaValue is Map
                ? Map<String, Object?>.from(safeMetaValue)
                : null;

        final safeValue = _prepareTracePayload(
          value,
          redactor,
          captureMode,
          resourceLimits,
        );
        final safeErrorText = error == null ? null : prepareText(error);
        final safeStackTrace = errorStackTrace == null
            ? null
            : StackTrace.fromString(
                prepareText(errorStackTrace),
              );
        final safeCorrelationId = correlationId == null
            ? null
            : _tracePayloadText(
                _prepareTracePayload(
                  correlationId,
                  redactor,
                  captureMode,
                  resourceLimits,
                ),
                resourceLimits,
              );

        final rawTxnId = Zone.current[_txnZoneKey];
        final zoneTxnId = rawTxnId is String ? rawTxnId : null;

        final additionalData = <String, Object?>{
          TraceKeys.category: safeCategoryId,
          TraceKeys.source: safeSource,
          TraceKeys.operation: safeOperation,
          if (safeTarget != null) TraceKeys.target: safeTarget,
          if (safeKey != null) TraceKeys.key: safeKey,
          if (value != null)
            TraceKeys.value: truncateValue(safeValue, cfg.maxValueLength),
          if (duration != null) TraceKeys.durationMs: duration.inMilliseconds,
          if (duration != null && cfg.slowThreshold != null)
            TraceKeys.slow: duration > cfg.slowThreshold!,
          TraceKeys.success: !isError,
          if (safeErrorText != null) TraceKeys.error: safeErrorText,
          if (zoneTxnId != null) TraceKeys.transactionId: zoneTxnId,
          if (safeCorrelationId != null)
            TraceKeys.correlationId: safeCorrelationId,
          if (safeMeta != null) TraceKeys.meta: safeMeta,
        };

        return ISpectLogData(
          message,
          key: safeLogKey,
          logLevel: logLevel ?? (isError ? LogLevel.error : LogLevel.info),
          additionalData: additionalData,
          exception:
              error is Exception ? const _PreparedTraceException() : null,
          error: error is Error ? _PreparedTraceError() : null,
          stackTrace: isError && cfg.attachStackOnError ? safeStackTrace : null,
          captureMode: DiagnosticCaptureMode.strict,
          resourceLimits: resourceLimits,
        );
      },
      // The snapshot already used cfg's resolved policy; a second pass would
      // overwrite an explicit trace policy with the global default.
      redact: false,
    );
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
    if (!isEnabled) return run();

    final cfg = config ?? const ISpectTraceConfig();
    final sw = Stopwatch()..start();
    try {
      final result = await run();
      sw.stop();

      if (!isEnabled) return result;
      if (!cfg.shouldLog(localSample: sample, isError: false)) return result;

      Object? projected;
      if (projectResult != null) {
        try {
          projected = projectResult(result);
        } catch (_) {
          _logProjectionFailure('traceAsync');
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
        config: cfg,
        sample: 1,
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

  /// A projection callback (`projectResult`/`projectEvent`) threw — the traced
  /// operation itself succeeded, so this is reported as a warning (not routed
  /// through the error handler) and never swallowed silently.
  void _logProjectionFailure(String wrapper) {
    log(
      '$wrapper: projection callback failed safely.',
      logLevel: LogLevel.warning,
    );
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
    if (!isEnabled) return run();

    final cfg = config ?? const ISpectTraceConfig();
    final sw = Stopwatch()..start();
    try {
      final result = run();
      sw.stop();

      if (!isEnabled) return result;
      if (!cfg.shouldLog(localSample: sample, isError: false)) return result;

      Object? projected;
      if (projectResult != null) {
        try {
          projected = projectResult(result);
        } catch (_) {
          _logProjectionFailure('traceSync');
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
        config: cfg,
        sample: 1,
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
    if (!isEnabled) return null;
    final cfg = config ?? const ISpectTraceConfig();
    final resourceLimits = (cfg.resourceLimits ?? options.resourceLimits)
      ..validate();
    final redactor = _traceRedactor(cfg);
    final captureMode = options.captureMode;
    String prepareText(Object? value) => _tracePayloadText(
          _prepareTracePayload(
            value,
            redactor,
            captureMode,
            resourceLimits,
          ),
          resourceLimits,
        );
    final preparedMeta = _prepareTracePayload(
      meta,
      redactor,
      captureMode,
      resourceLimits,
    );
    return ISpectTraceToken(
      stopwatch: Stopwatch()..start(),
      category: category,
      source: prepareText(source),
      operation: prepareText(operation),
      target: target == null ? null : prepareText(target),
      key: key == null ? null : prepareText(key),
      meta: preparedMeta is Map<String, Object?>
          ? preparedMeta
          : preparedMeta is Map
              ? Map<String, Object?>.from(preparedMeta)
              : null,
      config: cfg,
      correlationId: correlationId == null ? null : prepareText(correlationId),
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
    if (!isEnabled) return;
    final cfg = token.config ?? const ISpectTraceConfig();
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
      meta: _mergeTraceMeta(
        token.meta,
        meta,
        redactionActive: cfg.redact && ISpectRedaction.enabled,
        resourceLimits: cfg.resourceLimits ?? options.resourceLimits,
      ),
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
    if (!isEnabled) return stream;

    final corrId = correlationId ?? generateTraceId();
    final cfg = config ?? const ISpectTraceConfig();

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
          if (!isEnabled) return;
          if (!cfg.shouldLog(localSample: sample, isError: false)) return;
          Object? projected;
          if (projectEvent != null) {
            try {
              projected = projectEvent(data);
            } catch (_) {
              _logProjectionFailure('traceStream');
            }
          }
          trace(
            category: category,
            source: source,
            operation: '$operation.event',
            target: target,
            value: projected,
            success: true,
            sample: 1,
            config: cfg,
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
    if (!isEnabled) return run();

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

RedactionService? _traceRedactor(ISpectTraceConfig config) {
  if (!config.redact || !ISpectRedaction.enabled) return null;
  final sensitiveKeys = identical(config.redactKeys, defaultSensitiveKeys)
      ? null
      : config.redactKeys;
  return ISpectRedaction.resolveService(sensitiveKeys: sensitiveKeys);
}

Object? _prepareTracePayload(
  Object? value,
  RedactionService? redactor,
  DiagnosticCaptureMode captureMode,
  DiagnosticResourceLimits resourceLimits,
) {
  final redactionActive = redactor != null;
  final prepared = LogExportOutput.boundJsonValue(
    value,
    preserveTypes: redactionActive,
    replaceOversizedStrings: redactionActive,
    allowCustomSerialization: captureMode == DiagnosticCaptureMode.balanced,
    allowCustomStringification: captureMode == DiagnosticCaptureMode.balanced,
    resourceLimits: resourceLimits,
  );
  if (!redactionActive) return prepared;
  final redacted = redactor.redactForExport(
    LogExportOutput.replaceTruncatedPrefixes(
      prepared,
      resourceLimits: resourceLimits,
    ),
  );
  return LogExportOutput.boundJsonValue(
    redacted,
    replaceOversizedStrings: true,
    resourceLimits: resourceLimits,
  );
}

final class _PreparedTraceException implements Exception {
  const _PreparedTraceException();
}

final class _PreparedTraceError extends Error {}

Map<String, Object?>? _mergeTraceMeta(
  Map<String, Object?>? start,
  Map<String, Object?>? end, {
  required bool redactionActive,
  required DiagnosticResourceLimits resourceLimits,
}) {
  if (start == null && end == null) return null;
  final bounded = LogExportOutput.boundJsonValue(
    <String, Object?>{
      if (end != null) 'end': end,
      if (start != null) 'start': start,
    },
    preserveTypes: redactionActive,
    replaceOversizedStrings: redactionActive,
    resourceLimits: resourceLimits,
  );
  if (bounded is! Map) return null;

  final result = <String, Object?>{};
  void addBounded(Object? value) {
    if (value is Map<String, Object?>) {
      result.addAll(value);
    } else if (value is Map) {
      result.addAll(Map<String, Object?>.from(value));
    }
  }

  addBounded(bounded['start']);
  addBounded(bounded['end']);
  return result;
}

String _tracePayloadText(
  Object? value,
  DiagnosticResourceLimits resourceLimits,
) {
  if (value == null) return defaultPlaceholder;
  if (value is String) return value;
  if (value is bool || value is num) return value.toString();
  try {
    return LogExportOutput.truncateUtf8(
      jsonEncode(value),
      maxBytes: resourceLimits.maxCapturedValueBytes,
    );
  } catch (_) {
    return defaultPlaceholder;
  }
}
