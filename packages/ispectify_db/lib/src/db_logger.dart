import 'dart:async';
import 'dart:math';

import 'package:ispectify/ispectify.dart';
import 'config.dart';
import 'transaction.dart';

final class ISpectDbCore {
  const ISpectDbCore._();

  static ISpectDbConfig config = const ISpectDbConfig();
  static final Random _rng = Random();

  static bool _samplePass(double? localSample) {
    final s = localSample ?? config.sampleRate;
    if (s == null) return true;
    if (s <= 0) return false;
    if (s >= 1) return true;
    return _rng.nextDouble() < s;
  }

  static String genId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = _rng.nextInt(0x7fffffff);
    return ((now & 0xffffffff) ^ r).toRadixString(16) +
        _rng.nextInt(0xffffff).toRadixString(16).padLeft(6, '0');
  }

  static String? sqlDigest(String? statement) {
    if (statement == null || statement.isEmpty) return null;
    var s = statement.toLowerCase();
    s = s.replaceAll(RegExp(r"'[^']*'"), '?');
    s = s.replaceAll(RegExp(r'\"[^\"]*\"'), '?');
    s = s.replaceAll(RegExp(r'\b\d+\b'), '?');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    var hash = 5381;
    for (var i = 0; i < s.length; i++) {
      hash = ((hash << 5) + hash) ^ s.codeUnitAt(i);
    }
    final hex = (hash & 0x7fffffff).toRadixString(16);
    return '${s.substring(0, s.length > 80 ? 80 : s.length)}|$hex';
  }

  static Object? truncateValue(Object? value, int maxLen) {
    if (value == null) return null;
    if (value is String) {
      return value.length <= maxLen ? value : value.substring(0, maxLen) + '…';
    }

    return value;
  }

  static Object? redact(Object? data, List<String> keys) {
    if (data == null) return null;
    if (data is Map) {
      final out = <String, Object?>{};
      data.forEach((k, v) {
        final keyStr = k.toString();
        final keyLower = keyStr.toLowerCase();
        final hit = keys.any((rk) => rk.toLowerCase() == keyLower);
        out[keyStr] = hit ? '***' : redact(v, keys);
      });
      return out;
    }
    if (data is Iterable) {
      return data.map((e) => redact(e, keys)).toList();
    }
    return data;
  }

  static Map<String, Object?> clean(Map<String, Object?> m) {
    final out = <String, Object?>{};
    m.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      out[k] = v;
    });
    return out;
  }

  static String pickLogKey({required bool isError, required String operation}) {
    if (isError) return 'db-error';
    final op = operation.toLowerCase();
    if (op == 'query' || op == 'select' || op == 'read' || op == 'get') {
      return 'db-query';
    }
    return 'db-result';
  }

  static String buildMessage({
    required String source,
    required String operation,
    String? table,
    String? target,
    String? key,
    int? items,
    int? affected,
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
    if (duration != null) {
      details.add('Duration: ${duration.inMilliseconds}ms');
    }
    if (success != null) details.add('Success: $success');

    if (details.isNotEmpty) {
      buffer.write('\n${details.join('\n')}');
    }

    return buffer.toString();
  }
}

class ISpectDbToken {
  ISpectDbToken({
    required this.id,
    required this.startedAt,
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
  });

  final String id;
  final DateTime startedAt;
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

extension ISpectLoggerDb on ISpectLogger {
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
    final useRedact = redact ?? cfg.redact;
    final rKeys = redactKeys ?? cfg.redactKeys;
    final maxVal = maxValueLength ?? cfg.maxValueLength;
    final maxStmt = maxStatementLength ?? cfg.maxStatementLength;
    final maxArgs = maxArgsLength ?? cfg.maxArgsLength;

    final stmt = statement == null
        ? null
        : ISpectDbCore.truncateValue(statement, maxStmt) as String?;

    Object? truncateLeaves(Object? input, int maxLen) {
      if (input == null) return null;
      if (input is String) return ISpectDbCore.truncateValue(input, maxLen);
      if (input is Iterable) {
        return input.map((e) => truncateLeaves(e, maxLen)).toList();
      }
      if (input is Map) {
        final out = <String, Object?>{};
        input.forEach((k, v) {
          out[k.toString()] = truncateLeaves(v, maxLen);
        });
        return out;
      }
      return input;
    }

    final aBase = args == null
        ? null
        : (useRedact ? ISpectDbCore.redact(args, rKeys) : args);
    final a =
        aBase == null ? null : truncateLeaves(aBase, maxArgs) as List<Object?>?;

    final naBase = namedArgs == null
        ? null
        : (useRedact
            ? ISpectDbCore.redact(namedArgs, rKeys) as Map<String, Object?>
            : namedArgs);
    final na = naBase == null
        ? null
        : truncateLeaves(naBase, maxArgs) as Map<String, Object?>?;

    final m = meta == null
        ? null
        : (useRedact
            ? ISpectDbCore.redact(meta, rKeys) as Map<String, Object?>
            : meta);

    final txnId = transactionId ?? ISpectDbTxn.currentTransactionId();

    final val = projection ?? value;
    final valRed = useRedact ? ISpectDbCore.redact(val, rKeys) : val;
    final valTrunc = ISpectDbCore.truncateValue(valRed, maxVal);
    final valueForAdditional =
        valTrunc is String ? valTrunc : valTrunc?.toString();

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
        duration: duration,
        success: success,
        value: valTrunc);

    final isSlow =
        duration != null && ISpectDbCore.config.slowQueryThreshold != null
            ? duration > ISpectDbCore.config.slowQueryThreshold!
            : false;

    final additional = ISpectDbCore.clean({
      'source': source,
      'operation': operation,
      'statement': stmt,
      'statementDigest': digest,
      'target': target,
      'table': table,
      'key': key,
      'args': a,
      'namedArgs': na,
      'durationMs': duration?.inMilliseconds,
      'slow': isSlow ? true : null,
      'success': success,
      'affected': affected,
      'items': items,
      'value': valueForAdditional,
      'meta': m,
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

    logCustom(data);
  }

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
      result = await run();
      return result;
    } catch (e, s) {
      err = e;
      st = s;
      rethrow;
    } finally {
      sw.stop();
      final success = err == null;
      final items = success
          ? (itemsCountFromLength ??
              (result is List ? (result as List).length : null))
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
        transactionId: transactionId,
        errorStackTrace: st,
      );
    }
  }

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
  }) {
    return ISpectDbToken(
      id: ISpectDbCore.genId(),
      startedAt: DateTime.now(),
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
  }

  void dbEnd(
    ISpectDbToken token, {
    Object? value,
    bool? success,
    Object? error,
    int? affected,
    int? items,
    Map<String, Object?>? meta,
  }) {
    final duration = DateTime.now().difference(token.startedAt);
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
      duration: duration,
      meta: {...?token.meta, ...?meta},
      transactionId: token.transactionId,
    );
  }

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
      db(
        source: source,
        operation: 'transaction-begin',
        meta: meta,
        transactionId: txnId,
      );
    }
    var didSucceed = false;
    try {
      final result = await ISpectDbTxn.runInTransactionZone<T>(txnId, run);
      didSucceed = true;
      return result;
    } catch (e) {
      if (enableMarkers) {
        db(
          source: source,
          operation: 'transaction-rollback',
          meta: meta,
          transactionId: txnId,
          success: false,
          error: e,
        );
      }
      rethrow;
    } finally {
      if (enableMarkers && didSucceed) {
        db(
          source: source,
          operation: 'transaction-commit',
          meta: meta,
          transactionId: txnId,
          success: true,
        );
      }
    }
  }
}
