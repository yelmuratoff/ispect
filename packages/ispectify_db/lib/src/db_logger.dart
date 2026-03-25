import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/constants.dart';
import 'package:ispectify_db/src/db_core.dart';
import 'package:ispectify_db/src/db_token.dart';
import 'package:ispectify_db/src/transaction.dart';

/// Database logging extension on [ISpectLogger].
///
/// Provides four APIs for different use-cases:
/// - [db] — fire-and-forget single log entry.
/// - [dbTrace] — wraps an async operation, auto-measures duration.
/// - [dbStart]/[dbEnd] — manual span for cases where an async wrapper is
///   impractical (e.g. stream-based or callback-driven code).
/// - [dbTransaction] — groups nested calls under one transaction ID via [Zone].
extension ISpectLoggerDb on ISpectLogger {
  /// Logs a single database operation.
  ///
  /// Only [source] and [operation] are required. All other parameters are
  /// optional and adapt to different storage types:
  /// - **SQL**: [statement], [args], [namedArgs], [table], [affected], [items]
  /// - **Key-Value / Secure**: [key], [value]
  /// - **File / Blob**: [target] (path), [sizeBytes]
  /// - **Cache**: [key], [value], [cacheHit], [sizeBytes]
  ///
  /// Per-call [sample], [redact], and [redactKeys] override the global config.
  void db({
    required String source,
    required String operation,
    String? statement,
    String? target,
    String? table,
    String? key,
    Object? value,
    List<Object?>? args,
    Map<String, Object?>? namedArgs,
    bool? success,
    Object? error,
    int? affected,
    int? items,
    int? sizeBytes,
    bool? cacheHit,
    Duration? duration,
    Map<String, Object?>? meta,
    Object? projection,
    double? sample,
    bool? redact,
    List<String>? redactKeys,
    int? maxValueLength,
    int? maxArgsLength,
    int? maxStatementLength,
    String? transactionId,
    StackTrace? errorStackTrace,
  }) {
    if (!ISpectDbCore.shouldLog(sample)) return;

    final cfg = ISpectDbCore.config;
    final shouldRedact = redact ?? cfg.redact;
    final sensitiveKeys = redactKeys ?? cfg.redactKeys;
    final maxArgsLen = maxArgsLength ?? cfg.maxArgsLength;

    // Local closure — eliminates repeated shouldRedact + sensitiveKeys args.
    Object? redactData(Object? data) => ISpectDbCore.redactIfNeeded(
          data,
          shouldRedact: shouldRedact,
          keys: sensitiveKeys,
        );

    final truncatedStmt = _truncateToString(
      statement,
      maxStatementLength ?? cfg.maxStatementLength,
    );

    final processedArgs = _processPositionalArgs(
      args,
      shouldRedact: shouldRedact,
      sensitiveKeys: sensitiveKeys,
      statement: statement,
      maxLen: maxArgsLen,
    );

    final processedNamedArgs = _processNamedArgs(
      redactData(namedArgs),
      maxLen: maxArgsLen,
    );

    final processedMeta = redactData(meta);
    final txnId = transactionId ?? ISpectDbTxn.currentTransactionId();

    final truncatedValue = ISpectDbCore.truncateValue(
      redactData(projection ?? value),
      maxValueLength ?? cfg.maxValueLength,
    );
    final valueForAdditional =
        truncatedValue is String ? truncatedValue : truncatedValue?.toString();

    final digest = ISpectDbCore.sqlDigest(statement);

    final isError = (success == false) || (error != null);
    final keyName =
        ISpectDbCore.pickLogKey(isError: isError, operation: operation);

    final message = ISpectDbCore.buildMessage(
      source: source,
      operation: operation,
      table: table,
      target: target,
      key: key,
      items: items,
      affected: affected,
      sizeBytes: sizeBytes,
      cacheHit: cacheHit,
      duration: duration,
      success: success,
      value: truncatedValue,
    );

    final threshold = cfg.slowQueryThreshold;
    final isSlow =
        duration != null && threshold != null && duration > threshold;

    final additional = ISpectDbCore.clean({
      DbLogKeys.source: source,
      DbLogKeys.operation: operation,
      DbLogKeys.statement: shouldRedact ? digest : truncatedStmt,
      DbLogKeys.statementDigest: digest,
      DbLogKeys.target: target,
      DbLogKeys.table: table,
      DbLogKeys.key: key,
      DbLogKeys.args: processedArgs,
      DbLogKeys.namedArgs: processedNamedArgs,
      DbLogKeys.durationMs: duration?.inMilliseconds,
      DbLogKeys.slow: isSlow ? true : null,
      DbLogKeys.success: success,
      DbLogKeys.affected: affected,
      DbLogKeys.items: items,
      DbLogKeys.sizeBytes: sizeBytes,
      DbLogKeys.cacheHit: cacheHit,
      DbLogKeys.value: valueForAdditional,
      DbLogKeys.meta: processedMeta,
      DbLogKeys.transactionId: txnId,
      DbLogKeys.error: error?.toString(),
    });

    final data = ISpectLogData(
      message,
      key: keyName,
      title: keyName,
      logLevel: isError ? LogLevel.error : LogLevel.info,
      additionalData: additional,
      stackTrace: isError && cfg.attachStackOnError
          ? (errorStackTrace ?? StackTrace.current)
          : null,
    );

    logData(data);
  }

  /// Wraps [run] with automatic timing, error capture, and logging.
  ///
  /// Returns the result of [run]. If [run] throws, the error is logged and
  /// re-thrown. Duration is measured with a monotonic [Stopwatch].
  ///
  /// When [sampleRate] (global or per-call) rejects, [run] still executes
  /// but no log entry is produced.
  Future<T> dbTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? statement,
    String? target,
    String? table,
    String? key,
    List<Object?>? args,
    Map<String, Object?>? namedArgs,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectResult,
    double? sample,
    bool? redact,
    List<String>? redactKeys,
    int? maxValueLength,
    int? maxArgsLength,
    int? maxStatementLength,
    int? itemsCountFromLength,
    int? affectedOverride,
    int? sizeBytes,
    bool? cacheHit,
    String? transactionId,
  }) async {
    if (!ISpectDbCore.shouldLog(sample)) {
      return run();
    }
    final sw = Stopwatch()..start();
    late T result;
    Object? err;
    StackTrace? st;
    try {
      // ignore: join_return_with_assignment
      result = await run(); // `result` is used in `finally`.
      return result;
    } catch (e, s) {
      err = e;
      st = s;
      rethrow;
    } finally {
      sw.stop();
      try {
        final success = err == null;
        final items = success
            ? (itemsCountFromLength ?? (result is List ? result.length : null))
            : null;
        final projection =
            success && projectResult != null ? projectResult(result) : null;
        db(
          source: source,
          operation: operation,
          statement: statement,
          target: target,
          table: table,
          key: key,
          args: args,
          namedArgs: namedArgs,
          success: success,
          error: err,
          affected: affectedOverride,
          items: items,
          duration: sw.elapsed,
          meta: meta,
          projection: projection,
          sample: sample,
          redact: redact,
          redactKeys: redactKeys,
          maxValueLength: maxValueLength,
          maxArgsLength: maxArgsLength,
          maxStatementLength: maxStatementLength,
          sizeBytes: sizeBytes,
          cacheHit: cacheHit,
          transactionId: transactionId,
          errorStackTrace: st,
        );
      } catch (loggingError) {
        // Prevent logging failure from masking the original error.
        // In debug mode, surface the issue for self-diagnosis.
        assert(() {
          // ignore: avoid_print
          print('ISpectDbTrace: logging failed — $loggingError');
          return true;
        }());
      }
    }
  }

  /// Starts a manual span. Returns an [ISpectDbToken] that should be passed
  /// to [dbEnd] when the operation completes.
  ///
  /// Prefer [dbTrace] for simple async operations. Use [dbStart]/[dbEnd]
  /// when the operation lifetime cannot be expressed as a single `Future`.
  ISpectDbToken dbStart({
    String? source,
    String? operation,
    String? statement,
    String? target,
    String? table,
    String? key,
    List<Object?>? args,
    Map<String, Object?>? namedArgs,
    Map<String, Object?>? meta,
    String? transactionId,
  }) =>
      ISpectDbToken(
        stopwatch: Stopwatch()..start(),
        source: source,
        operation: operation,
        statement: statement,
        target: target,
        table: table,
        key: key,
        args: args,
        namedArgs: namedArgs,
        meta: meta,
        transactionId: transactionId ?? ISpectDbTxn.currentTransactionId(),
      );

  /// Finalizes a span started by [dbStart], logging the result with
  /// measured duration. Stops the internal [Stopwatch] on the [token].
  void dbEnd(
    ISpectDbToken token, {
    Object? value,
    bool? success,
    Object? error,
    int? affected,
    int? items,
    int? sizeBytes,
    bool? cacheHit,
    Map<String, Object?>? meta,
  }) {
    token.stopTiming();
    final duration = token.elapsed;
    db(
      source: token.source ?? dbDefaultSource,
      operation: token.operation ?? dbDefaultOperation,
      statement: token.statement,
      target: token.target,
      table: token.table,
      key: token.key,
      value: value,
      args: token.args,
      namedArgs: token.namedArgs,
      success: success ?? (error == null),
      error: error,
      affected: affected,
      items: items,
      sizeBytes: sizeBytes,
      cacheHit: cacheHit,
      duration: duration,
      meta: {...?token.meta, ...?meta},
      transactionId: token.transactionId,
    );
  }

  /// Truncates and converts to [String?] in one step.
  static String? _truncateToString(String? value, int maxLen) {
    if (value == null) return null;
    final truncated = ISpectDbCore.truncateValue(value, maxLen);
    return truncated is String ? truncated : truncated?.toString();
  }

  /// Redacts and truncates positional [args].
  static List<Object?>? _processPositionalArgs(
    List<Object?>? args, {
    required bool shouldRedact,
    required List<String> sensitiveKeys,
    required String? statement,
    required int maxLen,
  }) {
    if (args == null) return null;
    final redacted = shouldRedact
        ? ISpectDbCore.redactPositionalArgs(args, sensitiveKeys, statement)
        : args;
    final truncated = truncateLeaves(redacted, maxLength: maxLen);
    return truncated is List ? truncated.cast<Object?>() : null;
  }

  /// Normalizes redacted named args into a typed [Map] after truncation.
  static Map<String, Object?>? _processNamedArgs(
    Object? redacted, {
    required int maxLen,
  }) {
    if (redacted == null) return null;
    final truncated = truncateLeaves(redacted, maxLength: maxLen);
    if (truncated is Map) {
      return Map<String, Object?>.fromEntries(
        truncated.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return null;
  }

  void _logTxnMarker({
    required String source,
    required String operation,
    required String txnId,
    Map<String, Object?>? meta,
    bool? success,
    Object? error,
  }) {
    db(
      source: source,
      operation: operation,
      meta: meta,
      transactionId: txnId,
      success: success,
      error: error,
    );
  }

  /// Runs [run] inside a transaction zone that propagates a shared
  /// transaction ID to all nested [db]/[dbTrace] calls.
  ///
  /// **Nested transactions**: calling [dbTransaction] inside another
  /// [dbTransaction] replaces the zone-propagated ID for the inner scope.
  /// Inner [db]/[dbTrace] calls will use the inner transaction ID;
  /// outer calls retain the outer ID. This is a flat model — there is
  /// no parent-child linking between transaction IDs.
  ///
  /// Optionally emits `transaction-begin`, `transaction-commit`, and
  /// `transaction-rollback` marker logs (controlled by [logMarkers] or
  /// [ISpectDbConfig.enableTransactionMarkers]).
  Future<T> dbTransaction<T>({
    required Future<T> Function() run,
    String source = dbDefaultSource,
    Map<String, Object?>? meta,
    bool? logMarkers,
  }) async {
    final cfg = ISpectDbCore.config;
    final enableMarkers = logMarkers ?? cfg.enableTransactionMarkers;
    final txnId = ISpectDbCore.genId();
    if (enableMarkers) {
      _logTxnMarker(
        source: source,
        operation: DbTxnOps.begin,
        txnId: txnId,
        meta: meta,
      );
    }
    var didSucceed = false;
    try {
      final result = await ISpectDbTxn.runInTransactionZone<T>(txnId, run);
      didSucceed = true;
      return result;
    } catch (e) {
      if (enableMarkers) {
        _logTxnMarker(
          source: source,
          operation: DbTxnOps.rollback,
          txnId: txnId,
          meta: meta,
          success: false,
          error: e,
        );
      }
      rethrow;
    } finally {
      if (enableMarkers && didSucceed) {
        _logTxnMarker(
          source: source,
          operation: DbTxnOps.commit,
          txnId: txnId,
          meta: meta,
          success: true,
        );
      }
    }
  }
}
