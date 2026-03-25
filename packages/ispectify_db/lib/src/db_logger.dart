import 'dart:async';
import 'dart:math';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/transaction.dart';

/// Internal utilities for DB logging: ID generation, SQL fingerprinting,
/// value redaction/truncation, and message formatting.
///
/// Not intended for direct use — prefer the [ISpectLoggerDb] extension methods
/// ([db], [dbTrace], [dbStart]/[dbEnd], [dbTransaction]).
final class ISpectDbCore {
  const ISpectDbCore._();

  /// Current configuration applied to all DB log calls.
  static ISpectDbConfig config = ISpectDbConfig();

  static final Random _random = Random();

  static final RegExp _singleQuoteRe = RegExp("'[^']*'");
  static final RegExp _doubleQuoteRe = RegExp(r'\"[^\"]*\"');
  static final RegExp _digitRe = RegExp(r'\b\d+\b');
  static final RegExp _whitespaceRe = RegExp(r'\s+');

  static bool _samplePass(double? localSample) =>
      samplePass(localSample ?? config.sampleRate);

  /// Generates a 16-character hex trace ID from timestamp + random bits.
  static String genId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = _random.nextInt(0x7fffffff);

    return (now & 0xffffffff).toRadixString(16).padLeft(8, '0') +
        r.toRadixString(16).padLeft(8, '0');
  }

  /// Normalizes a SQL [statement] by replacing literals and digits with `?`,
  /// then appends a DJB2 hash for grouping structurally identical queries.
  ///
  /// Returns `null` when [statement] is `null` or empty.
  static String? sqlDigest(String? statement) {
    if (statement == null || statement.isEmpty) return null;
    var s = statement.toLowerCase();
    s = s.replaceAll(_singleQuoteRe, '?');
    s = s.replaceAll(_doubleQuoteRe, '?');
    s = s.replaceAll(_digitRe, '?');
    s = s.replaceAll(_whitespaceRe, ' ').trim();

    var hash = 5381;
    for (var i = 0; i < s.length; i++) {
      hash = (((hash << 5) + hash) ^ s.codeUnitAt(i)) & 0xffffffff;
    }
    final hex = (hash & 0x7fffffff).toRadixString(16);
    return '${s.substring(0, s.length > 80 ? 80 : s.length)}|$hex';
  }

  /// Truncates [value] to [maxLen] characters if it is a [String].
  /// Non-string values are returned as-is.
  static Object? truncateValue(Object? value, int maxLen) {
    if (value == null) return null;
    if (value is String) return truncateString(value, maxLength: maxLen);
    return value;
  }

  /// Redacts values in [data] whose keys match any of the provided [keys].
  ///
  /// Delegates to [RedactionService.redactByKeys] — the shared implementation
  /// in the `ispectify` package.
  static Object? redact(Object? data, List<String> keys) =>
      RedactionService.redactByKeys(data, keys);

  /// Conditionally redacts [data] if [shouldRedact] is `true`, otherwise
  /// returns [data] unchanged. Returns `null` when [data] is `null`.
  static Object? redactIfNeeded(
    Object? data, {
    required bool shouldRedact,
    required List<String> keys,
  }) {
    if (data == null) return null;
    return shouldRedact ? redact(data, keys) : data;
  }

  /// Redacts positional arguments in a [List] when the SQL [statement]
  /// references columns that match any of the [keys].
  ///
  /// Because positional parameters (`?`) cannot be reliably mapped to specific
  /// column names in all SQL dialects, this method redacts **all** list values
  /// when the statement mentions at least one sensitive column name.
  /// If [statement] is `null`, all values are redacted as a precaution.
  static List<Object?> redactPositionalArgs(
    List<Object?> args,
    List<String> keys,
    String? statement,
  ) {
    if (args.isEmpty) return args;
    final stmtLower = statement?.toLowerCase();
    final sensitive = stmtLower == null ||
        keys.any((k) => stmtLower.contains(k.toLowerCase()));
    if (!sensitive) return args;
    return args.map((e) => e == null ? null : '***').toList();
  }

  /// Removes entries with `null` values or empty-string values.
  ///
  /// Delegates to [cleanMap] from `ispectify`.
  static Map<String, Object?> clean(Map<String, Object?> m) => cleanMap(m);

  /// Returns the log key based on [operation] type: `db-error`, `db-query`,
  /// or `db-result`.
  static String pickLogKey({required bool isError, required String operation}) {
    if (isError) return 'db-error';
    final op = operation.toLowerCase();
    if (op == 'query' || op == 'select' || op == 'read' || op == 'get') {
      return 'db-query';
    }
    return 'db-result';
  }

  /// Builds a human-readable log message from the provided fields.
  static String buildMessage({
    required String source,
    required String operation,
    String? table,
    String? target,
    String? key,
    int? items,
    int? affected,
    int? sizeBytes,
    bool? cacheHit,
    Duration? duration,
    bool? success,
    Object? value,
  }) {
    final buffer = StringBuffer('[$source] $operation');

    if (table != null && target != null) {
      buffer.write(' $table → $target');
    } else if (table != null) {
      buffer.write(' $table');
    } else if (target != null) {
      buffer.write(' $target');
    }

    final details = <String>[];
    if (key != null) details.add('Key: $key');
    if (value != null) details.add('Value: $value');
    if (items != null) details.add('Items: $items');
    if (affected != null) details.add('Affected: $affected');
    if (sizeBytes != null) details.add('Size: ${_formatBytes(sizeBytes)}');
    if (cacheHit != null) details.add('Cache: ${cacheHit ? 'HIT' : 'MISS'}');
    if (duration != null) {
      details.add('Duration: ${duration.inMilliseconds}ms');
    }
    if (success != null) details.add('Success: $success');

    if (details.isNotEmpty) {
      buffer.write('\n${details.join('\n')}');
    }

    return buffer.toString();
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Opaque handle returned by [ISpectLoggerDb.dbStart] that captures
/// the operation context and a running [Stopwatch].
///
/// Pass to [ISpectLoggerDb.dbEnd] to finalize the log entry with
/// measured duration and result data.
class ISpectDbToken {
  ISpectDbToken({
    required this.id,
    required Stopwatch stopwatch,
    this.source,
    this.operation,
    this.statement,
    this.target,
    this.table,
    this.key,
    this.args,
    this.namedArgs,
    this.meta,
    this.transactionId,
  }) : _stopwatch = stopwatch;

  final Stopwatch _stopwatch;

  /// Elapsed duration since [dbStart] was called.
  Duration get elapsed => _stopwatch.elapsed;

  final String id;
  final String? source;
  final String? operation;
  final String? statement;
  final String? target;
  final String? table;
  final String? key;
  final List<Object?>? args;
  final Map<String, Object?>? namedArgs;
  final Map<String, Object?>? meta;
  final String? transactionId;
}

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
    if (!ISpectDbCore._samplePass(sample)) return;

    final cfg = ISpectDbCore.config;
    final shouldRedact = redact ?? cfg.redact;
    final sensitiveKeys = redactKeys ?? cfg.redactKeys;
    final maxValueLen = maxValueLength ?? cfg.maxValueLength;
    final maxStmtLen = maxStatementLength ?? cfg.maxStatementLength;
    final maxArgsLen = maxArgsLength ?? cfg.maxArgsLength;

    final truncatedStmtRaw = statement == null
        ? null
        : ISpectDbCore.truncateValue(statement, maxStmtLen);
    final truncatedStmt =
        truncatedStmtRaw is String ? truncatedStmtRaw : truncatedStmtRaw?.toString();

    final redactedArgs = args == null
        ? null
        : (shouldRedact
            ? ISpectDbCore.redactPositionalArgs(args, sensitiveKeys, statement)
            : args);
    final truncatedArgsRaw = redactedArgs == null
        ? null
        : truncateLeaves(redactedArgs, maxLength: maxArgsLen);
    final processedArgs =
        truncatedArgsRaw is List ? truncatedArgsRaw.cast<Object?>() : null;

    final redactedNamedArgs = ISpectDbCore.redactIfNeeded(
      namedArgs,
      shouldRedact: shouldRedact,
      keys: sensitiveKeys,
    );
    final truncatedNamedArgsRaw = redactedNamedArgs == null
        ? null
        : truncateLeaves(redactedNamedArgs, maxLength: maxArgsLen);
    final processedNamedArgs = truncatedNamedArgsRaw is Map
        ? Map<String, Object?>.fromEntries(
            truncatedNamedArgsRaw.entries
                .map((e) => MapEntry(e.key.toString(), e.value)),
          )
        : truncatedNamedArgsRaw is Iterable
            ? <String, Object?>{'values': truncatedNamedArgsRaw}
            : null;

    final processedMeta = ISpectDbCore.redactIfNeeded(
      meta,
      shouldRedact: shouldRedact,
      keys: sensitiveKeys,
    );

    final txnId = transactionId ?? ISpectDbTxn.currentTransactionId();

    final rawValue = projection ?? value;
    final redactedValue = ISpectDbCore.redactIfNeeded(
      rawValue,
      shouldRedact: shouldRedact,
      keys: sensitiveKeys,
    );
    final truncatedValue = ISpectDbCore.truncateValue(redactedValue, maxValueLen);
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

    final threshold = ISpectDbCore.config.slowQueryThreshold;
    final isSlow =
        duration != null && threshold != null && duration > threshold;

    final additional = ISpectDbCore.clean({
      'source': source,
      'operation': operation,
      'statement': shouldRedact ? digest : truncatedStmt,
      'statementDigest': digest,
      'target': target,
      'table': table,
      'key': key,
      'args': processedArgs,
      'namedArgs': processedNamedArgs,
      'durationMs': duration?.inMilliseconds,
      'slow': isSlow ? true : null,
      'success': success,
      'affected': affected,
      'items': items,
      'sizeBytes': sizeBytes,
      'cacheHit': cacheHit,
      'value': valueForAdditional,
      'meta': processedMeta,
      'transactionId': txnId,
      'error': error?.toString(),
    });

    final data = ISpectLogData(
      message,
      key: keyName,
      title: keyName,
      logLevel: isError ? LogLevel.error : LogLevel.info,
      additionalData: additional,
      stackTrace: isError && ISpectDbCore.config.attachStackOnError
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
    if (!ISpectDbCore._samplePass(sample)) {
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
      } catch (_) {
        // Prevent logging failure from masking the original error.
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
        id: ISpectDbCore.genId(),
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
    token._stopwatch.stop();
    final duration = token.elapsed;
    db(
      source: token.source ?? 'custom',
      operation: token.operation ?? 'custom',
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
  /// Optionally emits `transaction-begin`, `transaction-commit`, and
  /// `transaction-rollback` marker logs (controlled by [logMarkers] or
  /// [ISpectDbConfig.enableTransactionMarkers]).
  Future<T> dbTransaction<T>({
    required Future<T> Function() run,
    String source = 'custom',
    Map<String, Object?>? meta,
    bool? logMarkers,
  }) async {
    final cfg = ISpectDbCore.config;
    final enableMarkers = logMarkers ?? cfg.enableTransactionMarkers;
    final txnId = ISpectDbCore.genId();
    if (enableMarkers) {
      _logTxnMarker(
        source: source,
        operation: 'transaction-begin',
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
          operation: 'transaction-rollback',
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
          operation: 'transaction-commit',
          txnId: txnId,
          meta: meta,
          success: true,
        );
      }
    }
  }
}
