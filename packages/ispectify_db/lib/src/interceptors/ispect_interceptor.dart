import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/core/interceptor.dart';
import 'package:ispectify_db/src/core/types.dart';
import 'package:ispectify_db/src/data/error.dart';
import 'package:ispectify_db/src/data/query.dart';
import 'package:ispectify_db/src/data/result.dart';
import 'package:ispectify_db/src/models/error.dart';
import 'package:ispectify_db/src/models/query.dart';
import 'package:ispectify_db/src/models/result.dart';
import 'package:ispectify_db/src/settings.dart';

class ISpectDbInterceptor implements DbInterceptor {
  ISpectDbInterceptor({
    ISpectify? logger,
    ISpectDbLoggerSettings settings = const ISpectDbLoggerSettings(),
    RedactionService? redactor,
  })  : _logger = logger ?? ISpectify(),
        _settings = settings,
        _redactor = redactor ?? RedactionService();

  final ISpectify _logger;
  final ISpectDbLoggerSettings _settings;
  final RedactionService _redactor;

  @override
  FutureOr<DbResult<T>> intercept<T>(
    DbOperation op,
    NextHandler<T> next,
  ) async {
    if (!_settings.enabled) return next(op);

    final useRedaction = _settings.enableRedaction;
    final redParams = useRedaction ? _redactor.redact(op.params) : op.params;
    final queryData = DbQueryData(
      operation: op.command.name.toUpperCase(),
      table: op.table,
      sql: op.sql,
      params: redParams is Map<String, dynamic>
          ? redParams
          : (redParams == null ? null : {'params': redParams}),
      driver: op.driver,
      database: op.database,
      host: op.host,
      port: op.port,
      schema: op.schema,
    );

    final q = DbQueryLog(
      op.sql ?? op.command.name,
      settings: _settings,
      queryData: queryData,
    );
    if (_settings.queryFilter?.call(q) ?? true) {
      if (_settings.printQuery) _logger.logCustom(q);
    }

    final sw = Stopwatch()..start();
    try {
      final DbResult<T> res = await Future.sync(() => next(op));
      sw.stop();

      final safeVal = useRedaction ? _redactor.redact(res.value) : res.value;
      final result = DbResultData(
        durationMs:
            res.durationMs == 0 ? sw.elapsedMilliseconds : res.durationMs,
        rowCount: res.rowCount,
        rows: safeVal,
        notice: res.notice,
      );
      final r = DbResultLog(
        op.sql ?? op.command.name,
        settings: _settings,
        queryData: queryData,
        resultData: result,
      );
      if (_settings.resultFilter?.call(r) ?? true) {
        if (_settings.printResult) _logger.logCustom(r);
      }
      return res;
    } catch (e, s) {
      sw.stop();
      final errData = DbErrorData(
        durationMs: sw.elapsedMilliseconds,
        exception: e,
        stackTrace: s,
      );
      final er = DbErrorLog(
        op.sql ?? op.command.name,
        settings: _settings,
        queryData: queryData,
        errorData: errData,
      );
      if (_settings.errorFilter?.call(er) ?? true) {
        if (_settings.printError) _logger.logCustom(er);
      }
      rethrow;
    }
  }
}
