import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/constants.dart';
import 'package:ispectify_db/src/db_core.dart';
import 'package:ispectify_db/src/db_preprocess_input.dart';
import 'package:ispectify_db/src/db_token.dart';
import 'package:ispectify_db/src/sql_digest.dart';
import 'package:ispectify_db/src/transaction.dart';

/// Database logging extension on [ISpectLogger].
///
/// All methods accept an optional [config] parameter. When omitted, the default
/// [ISpectDbConfig] is used. Pass a custom config to override sampling, redaction,
/// statement/arg length limits, and transaction marker settings per call-site.
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
    ISpectDbConfig config = const ISpectDbConfig(),
  }) {
    if (!options.enabled) return;
    if (!ISpectDbCore.shouldLog(sample, config)) return;

    final dbMeta = _preprocessDb(
      DbPreprocessInput(
        cfg: config,
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
      ),
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
      config: config,
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
    ISpectDbConfig config = const ISpectDbConfig(),
  }) async {
    if (!options.enabled) return run();
    if (!ISpectDbCore.shouldLog(sample, config)) return run();

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
      _logTraceResult(
        config: config,
        txnId: txnId,
        source: source,
        operation: operation,
        target: table ?? target,
        key: key,
        statement: statement,
        args: args,
        namedArgs: namedArgs,
        meta: meta,
        redact: redact,
        redactKeys: redactKeys,
        maxValueLength: maxValueLength,
        maxArgsLength: maxArgsLength,
        maxStatementLength: maxStatementLength,
        sizeBytes: sizeBytes,
        cacheHit: cacheHit,
        sample: sample,
        elapsed: sw.elapsed,
        err: err,
        st: st,
        items: err == null
            ? (itemsCountFromLength ?? (result is List ? result.length : null))
            : null,
        affectedOverride: affectedOverride,
        projected: _safeProject(err == null, projectResult, () => result),
      );
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
    ISpectDbConfig config = const ISpectDbConfig(),
  }) {
    if (!options.enabled) return run();
    if (!ISpectDbCore.shouldLog(sample, config)) return run();

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
      _logTraceResult(
        config: config,
        txnId: txnId,
        source: source,
        operation: operation,
        target: table ?? target,
        key: key,
        statement: statement,
        args: args,
        namedArgs: namedArgs,
        meta: meta,
        redact: redact,
        redactKeys: redactKeys,
        maxValueLength: maxValueLength,
        maxArgsLength: maxArgsLength,
        maxStatementLength: maxStatementLength,
        sizeBytes: sizeBytes,
        cacheHit: cacheHit,
        sample: sample,
        elapsed: sw.elapsed,
        err: err,
        st: st,
        items: err == null
            ? (itemsCountFromLength ?? (result is List ? result.length : null))
            : null,
        affectedOverride: affectedOverride,
        projected: _safeProject(err == null, projectResult, () => result),
      );
    }
  }

  /// Shared finally-block logic for [dbTrace] and [dbTraceSync].
  void _logTraceResult({
    required ISpectDbConfig config,
    required String? txnId,
    required String source,
    required String operation,
    required String? target,
    required String? key,
    required String? statement,
    required List<Object?>? args,
    required Map<String, Object?>? namedArgs,
    required Map<String, Object?>? meta,
    required bool? redact,
    required List<String>? redactKeys,
    required int? maxValueLength,
    required int? maxArgsLength,
    required int? maxStatementLength,
    required int? sizeBytes,
    required bool? cacheHit,
    required double? sample,
    required Duration elapsed,
    required Object? err,
    required StackTrace? st,
    required int? items,
    required int? affectedOverride,
    required Object? projected,
  }) {
    try {
      final success = err == null;

      final dbMeta = _preprocessDb(
        DbPreprocessInput(
          cfg: config,
          statement: statement,
          args: args,
          namedArgs: namedArgs,
          table: target,
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
        ),
      );

      trace(
        category: dbCategory,
        source: source,
        operation: operation,
        target: target,
        key: key,
        success: success,
        error: err,
        errorStackTrace: st,
        duration: elapsed,
        sample: sample,
        config: config,
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

  /// Safely project a result value, returning null on failure.
  static Object? _safeProject<T>(
    bool success,
    Object? Function(T value)? projectResult,
    T Function() getResult,
  ) {
    if (!success || projectResult == null) return null;
    try {
      return projectResult(getResult());
    } catch (_) {
      return null;
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
    ISpectDbConfig config = const ISpectDbConfig(),
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
      config: config,
    );
  }

  /// Runs [run] inside a transaction zone. Delegates to [traceTransaction].
  Future<T> dbTransaction<T>({
    required Future<T> Function() run,
    String source = dbDefaultSource,
    Map<String, Object?>? meta,
    bool? logMarkers,
    ISpectDbConfig config = const ISpectDbConfig(),
  }) async {
    final enableMarkers = logMarkers ?? config.enableTransactionMarkers;
    return traceTransaction(
      category: dbCategory,
      source: source,
      run: run,
      logMarkers: enableMarkers,
    );
  }

  /// Preprocesses DB-specific fields into a meta map for trace().
  static Map<String, Object?> _preprocessDb(DbPreprocessInput input) {
    final shouldRedact = input.shouldRedact;
    final sensitiveKeys = input.sensitiveKeys.toSet();
    final maxArgsLen = input.resolvedMaxArgsLength;

    final redactor = shouldRedact
        ? RedactionService(
            sensitiveKeys: sensitiveKeys,
            placeholder: redactedMask,
          )
        : null;

    Object? redactData(Object? data) =>
        data == null ? null : (redactor?.redact(data) ?? data);

    final truncatedStmt = _truncateToString(
      input.statement,
      input.resolvedMaxStatementLength,
    );

    final processedArgs = _processPositionalArgs(
      input.args,
      redactor: redactor,
      sensitiveKeys: sensitiveKeys,
      statement: input.statement,
      maxLen: maxArgsLen,
    );

    final processedNamedArgs = _processNamedArgs(
      redactData(input.namedArgs),
      maxLen: maxArgsLen,
    );

    final processedMeta = redactData(input.meta);
    final digest = DbSqlDigest.compute(input.statement);

    final truncatedValue = ISpectDbCore.truncateValue(
      redactData(input.value),
      input.resolvedMaxValueLength,
    );

    final errorText = input.error == null
        ? null
        : shouldRedact
            ? RedactionService.redactExportString(
                '${input.error}',
                sensitiveKeys,
              )
            : '${input.error}';

    return ISpectDbCore.clean(<String, Object?>{
      'statement': shouldRedact ? digest : truncatedStmt,
      'statementDigest': digest,
      if (input.table != null) 'table': input.table,
      if (input.key != null) 'key': input.key,
      'args': processedArgs,
      'namedArgs': processedNamedArgs,
      if (input.affected != null) 'affected': input.affected,
      if (input.items != null) 'items': input.items,
      if (input.sizeBytes != null) 'sizeBytes': input.sizeBytes,
      if (input.cacheHit != null) 'cacheHit': input.cacheHit,
      if (truncatedValue != null) 'value': truncatedValue,
      if (processedMeta != null) 'userMeta': processedMeta,
      if (errorText != null) 'dbError': errorText,
    });
  }

  static String? _truncateToString(String? value, int maxLen) {
    if (value == null) return null;
    final truncated = ISpectDbCore.truncateValue(value, maxLen);
    return truncated is String ? truncated : truncated?.toString();
  }

  static List<Object?>? _processPositionalArgs(
    List<Object?>? args, {
    required RedactionService? redactor,
    required Iterable<String> sensitiveKeys,
    required String? statement,
    required int maxLen,
  }) {
    if (args == null) return null;
    var processed = args;
    if (redactor != null) {
      final columnMasked =
          ISpectDbCore.redactPositionalArgs(args, sensitiveKeys, statement);
      final patternMasked = redactor.redact(columnMasked);
      processed =
          patternMasked is List ? patternMasked.cast<Object?>() : columnMasked;
    }
    final truncated = truncateLeaves(processed, maxLength: maxLen);
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
