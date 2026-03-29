import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/constants.dart';
import 'package:ispectify_db/src/db_core.dart';
import 'package:ispectify_db/src/db_token.dart';
import 'package:ispectify_db/src/transaction.dart';

/// Database logging extension on [ISpectLogger].
///
/// All methods delegate to the unified trace API via [trace]/[traceAsync]/
/// [traceTransaction], placing DB-specific data in [TraceKeys.meta].
extension ISpectLoggerDb on ISpectLogger {
  /// Logs a single database operation via [trace].
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
    if (!options.enabled) return;
    if (!ISpectDbCore.shouldLog(sample)) return;

    final cfg = ISpectDbCore.config;
    final dbMeta = _preprocessDb(
      cfg: cfg,
      statement: statement,
      args: args,
      namedArgs: namedArgs,
      table: table,
      key: key,
      value: projection ?? value,
      affected: affected,
      items: items,
      sizeBytes: sizeBytes,
      cacheHit: cacheHit,
      meta: meta,
      redact: redact,
      redactKeys: redactKeys,
      maxValueLength: maxValueLength,
      maxArgsLength: maxArgsLength,
      maxStatementLength: maxStatementLength,
      error: error,
    );

    final txnId = transactionId ?? ISpectDbTxn.currentTransactionId();
    final isError = (success == false) || (error != null);

    trace(
      category: dbCategory,
      source: source,
      operation: operation,
      target: table ?? target,
      key: key,
      success: success ?? (error == null),
      error: error,
      errorStackTrace: errorStackTrace,
      duration: duration,
      sample: sample,
      config: cfg,
      meta: dbMeta,
      correlationId: txnId,
      logLevel: isError ? LogLevel.error : null,
    );
  }

  /// Wraps [run] with automatic timing and delegates to [traceAsync].
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
    if (!options.enabled) return run();
    if (!ISpectDbCore.shouldLog(sample)) return run();

    final cfg = ISpectDbCore.config;
    final txnId = transactionId ?? ISpectDbTxn.currentTransactionId();

    final sw = Stopwatch()..start();
    late T result;
    Object? err;
    StackTrace? st;
    try {
      // ignore: join_return_with_assignment
      result = await run();
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
        Object? projected;
        if (success && projectResult != null) {
          try {
            projected = projectResult(result);
          } catch (_) {}
        }

        final dbMeta = _preprocessDb(
          cfg: cfg,
          statement: statement,
          args: args,
          namedArgs: namedArgs,
          table: table,
          key: key,
          value: projected,
          affected: affectedOverride,
          items: items,
          sizeBytes: sizeBytes,
          cacheHit: cacheHit,
          meta: meta,
          redact: redact,
          redactKeys: redactKeys,
          maxValueLength: maxValueLength,
          maxArgsLength: maxArgsLength,
          maxStatementLength: maxStatementLength,
          error: err,
        );

        trace(
          category: dbCategory,
          source: source,
          operation: operation,
          target: table ?? target,
          key: key,
          success: success,
          error: err,
          errorStackTrace: st,
          duration: sw.elapsed,
          sample: sample,
          config: cfg,
          meta: dbMeta,
          correlationId: txnId,
        );
      } catch (loggingError) {
        assert(() {
          // ignore: avoid_print
          print('ISpectDbTrace: logging failed — $loggingError');
          return true;
        }());
      }
    }
  }

  /// Synchronous version of [dbTrace].
  T dbTraceSync<T>({
    required String source,
    required String operation,
    required T Function() run,
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
  }) {
    if (!options.enabled) return run();
    if (!ISpectDbCore.shouldLog(sample)) return run();

    final cfg = ISpectDbCore.config;
    final txnId = transactionId ?? ISpectDbTxn.currentTransactionId();

    final sw = Stopwatch()..start();
    late T result;
    Object? err;
    StackTrace? st;
    try {
      return result = run();
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
        Object? projected;
        if (success && projectResult != null) {
          try {
            projected = projectResult(result);
          } catch (_) {}
        }

        final dbMeta = _preprocessDb(
          cfg: cfg,
          statement: statement,
          args: args,
          namedArgs: namedArgs,
          table: table,
          key: key,
          value: projected,
          affected: affectedOverride,
          items: items,
          sizeBytes: sizeBytes,
          cacheHit: cacheHit,
          meta: meta,
          redact: redact,
          redactKeys: redactKeys,
          maxValueLength: maxValueLength,
          maxArgsLength: maxArgsLength,
          maxStatementLength: maxStatementLength,
          error: err,
        );

        trace(
          category: dbCategory,
          source: source,
          operation: operation,
          target: table ?? target,
          key: key,
          success: success,
          error: err,
          errorStackTrace: st,
          duration: sw.elapsed,
          sample: sample,
          config: cfg,
          meta: dbMeta,
          correlationId: txnId,
        );
      } catch (loggingError) {
        assert(() {
          error('ISpectDbTrace: logging failed — $loggingError');
          return true;
        }());
      }
    }
  }

  /// Starts a manual span.
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

  /// Finalizes a span started by [dbStart].
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
      duration: token.elapsed,
      meta: {...?token.meta, ...?meta},
      transactionId: token.transactionId,
    );
  }

  /// Runs [run] inside a transaction zone. Delegates to [traceTransaction].
  Future<T> dbTransaction<T>({
    required Future<T> Function() run,
    String source = dbDefaultSource,
    Map<String, Object?>? meta,
    bool? logMarkers,
  }) async {
    final enableMarkers =
        logMarkers ?? ISpectDbCore.config.enableTransactionMarkers;
    return traceTransaction(
      category: dbCategory,
      source: source,
      run: run,
      logMarkers: enableMarkers,
    );
  }

  /// Preprocesses DB-specific fields into a meta map for trace().
  static Map<String, Object?> _preprocessDb({
    required ISpectDbConfig cfg,
    String? statement,
    List<Object?>? args,
    Map<String, Object?>? namedArgs,
    String? table,
    String? key,
    Object? value,
    int? affected,
    int? items,
    int? sizeBytes,
    bool? cacheHit,
    Map<String, Object?>? meta,
    bool? redact,
    List<String>? redactKeys,
    int? maxValueLength,
    int? maxArgsLength,
    int? maxStatementLength,
    Object? error,
  }) {
    final shouldRedact = redact ?? cfg.redact;
    final sensitiveKeys = redactKeys ?? cfg.redactKeys.toList();
    final maxArgsLen = maxArgsLength ?? cfg.maxArgsLength;

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
    final digest = ISpectDbCore.sqlDigest(statement);

    final truncatedValue = ISpectDbCore.truncateValue(
      redactData(value),
      maxValueLength ?? cfg.maxValueLength,
    );

    return ISpectDbCore.clean(<String, Object?>{
      'statement': shouldRedact ? digest : truncatedStmt,
      'statementDigest': digest,
      if (table != null) 'table': table,
      if (key != null) 'key': key,
      'args': processedArgs,
      'namedArgs': processedNamedArgs,
      if (affected != null) 'affected': affected,
      if (items != null) 'items': items,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (cacheHit != null) 'cacheHit': cacheHit,
      if (truncatedValue != null) 'value': truncatedValue,
      if (processedMeta != null) 'userMeta': processedMeta,
      if (error != null) 'dbError': '$error',
    });
  }

  static String? _truncateToString(String? value, int maxLen) {
    if (value == null) return null;
    final truncated = ISpectDbCore.truncateValue(value, maxLen);
    return truncated is String ? truncated : truncated?.toString();
  }

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
}
