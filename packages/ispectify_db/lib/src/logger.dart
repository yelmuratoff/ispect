import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/data/error.dart';
import 'package:ispectify_db/src/data/query.dart';
import 'package:ispectify_db/src/data/result.dart';
import 'package:ispectify_db/src/models/error.dart';
import 'package:ispectify_db/src/models/query.dart';
import 'package:ispectify_db/src/models/result.dart';
import 'package:ispectify_db/src/settings.dart';

/// Generic DB logger wrapper.
///
/// Use `run` to wrap any DB operation (query/execute) to emit logs
/// for query, result and error. It measures duration and supports redaction.
class ISpectDbLogger {
  ISpectDbLogger({
    ISpectify? logger,
    this.settings = const ISpectDbLoggerSettings(),
    RedactionService? redactor,
  })  : _logger = logger ?? ISpectify(),
        _redactor = redactor ?? RedactionService();

  final ISpectify _logger;
  final ISpectDbLoggerSettings settings;
  RedactionService _redactor;

  void configure({
    ISpectDbLoggerSettings? settings,
    RedactionService? redactor,
  }) {
    if (settings != null) _settings = settings;
    if (redactor != null) _redactor = redactor;
  }

  // Internal mutable reference to support configure()
  late ISpectDbLoggerSettings _settings = settings;

  /// Wrap a DB operation and emit logs.
  ///
  /// Provide [operation], [table], [sql], and [params] metadata to enrich logs.
  /// The [executor] performs the DB call and returns result rows/driver object.
  Future<T> run<T>({
    required String operation,
    required FutureOr<T> Function() executor,
    String? table,
    String? sql,
    Map<String, dynamic>? params,
    String? driver,
    String? database,
    String? host,
    int? port,
    String? schema,
  }) async {
    if (!_settings.enabled) {
      return await executor();
    }
    final useRedaction = _settings.enableRedaction;
    final redactedParams = useRedaction ? _redactor.redact(params) : params;
    final queryData = DbQueryData(
      operation: operation,
      table: table,
      sql: sql,
      params: redactedParams is Map<String, dynamic>
          ? redactedParams
          : (redactedParams == null ? null : {'params': redactedParams}),
      driver: driver,
      database: database,
      host: host,
      port: port,
      schema: schema,
    );
    final queryLog = DbQueryLog(
      sql ?? operation,
      settings: _settings,
      queryData: queryData,
    );
    if (_settings.queryFilter?.call(queryLog) ?? true) {
      if (_settings.printQuery) {
        _logger.logCustom(queryLog);
      }
    }

    final sw = Stopwatch()..start();
    try {
      final T res = await Future.sync(executor);
      sw.stop();
      final safeRes = useRedaction ? _redactor.redact(res) : res;
      final resultData = DbResultData(
        durationMs: sw.elapsedMilliseconds,
        rows: safeRes,
        // rowCount is best-effort if it's a List
        rowCount: safeRes is List ? safeRes.length : null,
      );
      final resultLog = DbResultLog(
        sql ?? operation,
        settings: _settings,
        queryData: queryData,
        resultData: resultData,
      );
      if (_settings.resultFilter?.call(resultLog) ?? true) {
        if (_settings.printResult) {
          _logger.logCustom(resultLog);
        }
      }
      return res;
    } catch (e, s) {
      sw.stop();
      final errorData = DbErrorData(
        durationMs: sw.elapsedMilliseconds,
        exception: e,
        stackTrace: s,
      );
      final errorLog = DbErrorLog(
        sql ?? operation,
        settings: _settings,
        queryData: queryData,
        errorData: errorData,
      );
      if (_settings.errorFilter?.call(errorLog) ?? true) {
        if (_settings.printError) {
          _logger.logCustom(errorLog);
        }
      }
      rethrow;
    }
  }
}
