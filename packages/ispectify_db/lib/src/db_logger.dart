import 'dart:async';
import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/constants.dart';
import 'package:ispectify_db/src/db_core.dart';
import 'package:ispectify_db/src/db_preprocess_input.dart';
import 'package:ispectify_db/src/db_token.dart';
import 'package:ispectify_db/src/message_formatter.dart';
import 'package:ispectify_db/src/sql_digest.dart';
import 'package:ispectify_db/src/transaction.dart';

const _dbProjectionNotProvided = _DbProjectionNotProvided();
const _dbKeyProbe = 'value';
final _dbKeyEmailPattern = RegExp(
  r'[^\s@:/]+(?:@|%40)[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}',
  caseSensitive: false,
);
final _dbKeySegmentDelimiters = RegExp(r'[:/|#.;,=?&\s]+');
final _dbKeyOpaqueSegment = RegExp(r'^[A-Za-z0-9_-]{16,}$');
final _dbKeyMixedRun = RegExp(
  '(?=[A-Za-z0-9]*[A-Za-z])(?=[A-Za-z0-9]*[0-9])[A-Za-z0-9]{8,}',
);
final _dbKeyPhoneSegment = RegExp(r'^\+?\d{7,15}$');
final _dbKeyDigitSequence = RegExp(r'\d(?:[\s().-]*\d)*');
final _dbKeyNonDigit = RegExp(r'\D');
final _dbKeyIsoDate = RegExp(r'(?<!\d)\d{4}-\d{2}-\d{2}(?!\d)');
const _dbKeyMinIdentifierDigits = 9;
const _dbKeyCredentialNamespaces = {'auth', 'sid', 'session', 'sessions'};
final _inertDbToken = ISpectDbToken(stopwatch: Stopwatch());

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
  ///
  /// A supplied [projection], including `null`, replaces [value].
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
    Object? projection = _dbProjectionNotProvided,
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
    if (!hasActiveConsumers) return;
    guardDiagnostics(
      this,
      () => _captureDb(
        source: source,
        operation: operation,
        statement: statement,
        args: args,
        namedArgs: namedArgs,
        table: table,
        target: target,
        key: key,
        value: value,
        error: error,
        success: success,
        affected: affected,
        items: items,
        sizeBytes: sizeBytes,
        cacheHit: cacheHit,
        duration: duration,
        meta: meta,
        projection: projection,
        sample: sample,
        redact: redact,
        redactKeys: redactKeys,
        maxValueLength: maxValueLength,
        maxArgsLength: maxArgsLength,
        maxStatementLength: maxStatementLength,
        transactionId: transactionId,
        errorStackTrace: errorStackTrace,
        config: config,
      ),
      what: 'Database trace capture',
    );
  }

  void _captureDb({
    required String source,
    required String operation,
    required String? statement,
    required List<Object?>? args,
    required Map<String, Object?>? namedArgs,
    required String? table,
    required String? target,
    required String? key,
    required Object? value,
    required Object? error,
    required bool? success,
    required int? affected,
    required int? items,
    required int? sizeBytes,
    required bool? cacheHit,
    required Duration? duration,
    required Map<String, Object?>? meta,
    required Object? projection,
    required double? sample,
    required bool? redact,
    required List<String>? redactKeys,
    required int? maxValueLength,
    required int? maxArgsLength,
    required int? maxStatementLength,
    required String? transactionId,
    required StackTrace? errorStackTrace,
    required ISpectDbConfig config,
  }) {
    final resolvedConfig = _resolveResourceConfig(config);
    final isError = (success == false) || (error != null);
    if (!resolvedConfig.shouldLog(isError: isError, localSample: sample)) {
      return;
    }

    final preprocessInput = DbPreprocessInput(
      cfg: resolvedConfig,
      statement: statement,
      args: args,
      namedArgs: namedArgs,
      table: table,
      key: key,
      value:
          identical(projection, _dbProjectionNotProvided) ? value : projection,
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
    final preprocessed = _preprocessDb(
      preprocessInput,
      errorStackTrace: errorStackTrace,
    );
    _emitDbTrace(
      resolvedConfig: resolvedConfig,
      traceConfig: _resolveTraceConfig(
        resolvedConfig,
        redact: redact,
        redactKeys: redactKeys,
      ),
      shouldRedact: preprocessInput.shouldRedact,
      source: source,
      operation: operation,
      target: table ??
          target ??
          DbSqlDigest.tableOf(
            statement,
            resourceLimits: resolvedConfig.resourceLimits!,
          ),
      success: success ?? (error == null),
      preprocessed: preprocessed,
      duration: duration,
      transactionId: transactionId ?? ISpectDbTxn.currentTransactionId(),
      sizeBytes: sizeBytes,
      cacheHit: cacheHit,
      logLevel: isError ? LogLevel.error : null,
    );
  }

  void _emitDbTrace({
    required ISpectDbConfig resolvedConfig,
    required ISpectDbConfig traceConfig,
    required bool shouldRedact,
    required String source,
    required String operation,
    required String? target,
    required bool success,
    required _PreprocessedDbTrace preprocessed,
    required Duration? duration,
    required String? transactionId,
    required int? sizeBytes,
    required bool? cacheHit,
    LogLevel? logLevel,
  }) {
    final resourceLimits = resolvedConfig.resourceLimits!;
    String? bound(String? value) => _boundNullableDbText(
          value,
          shouldRedact: shouldRedact,
          resourceLimits: resourceLimits,
        );
    final safeTarget = bound(target);
    final safeKey = bound(preprocessed.key);
    trace(
      category: dbCategory,
      source: _boundDbText(
        source,
        shouldRedact: shouldRedact,
        resourceLimits: resourceLimits,
      ),
      operation: _boundDbText(
        operation,
        shouldRedact: shouldRedact,
        resourceLimits: resourceLimits,
      ),
      target: safeTarget,
      key: safeKey,
      success: success,
      error: preprocessed.error,
      errorStackTrace: preprocessed.errorStackTrace,
      duration: duration,
      sample: 1,
      config: traceConfig,
      meta: preprocessed.meta,
      correlationId: bound(transactionId),
      logLevel: logLevel,
      consoleMessage: _buildDbConsoleMessage(
        operation: operation,
        table: safeTarget,
        key: safeKey,
        meta: preprocessed.meta,
        sizeBytes: sizeBytes,
        cacheHit: cacheHit,
        success: success,
      ),
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
    if (!hasActiveConsumers) return run();

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
        itemsCountFromLength: itemsCountFromLength,
        affectedOverride: affectedOverride,
        projectResult: projectResult,
        getResult: () => result,
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
    if (!hasActiveConsumers) return run();

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
        itemsCountFromLength: itemsCountFromLength,
        affectedOverride: affectedOverride,
        projectResult: projectResult,
        getResult: () => result,
      );
    }
  }

  /// Shared finally-block logic for [dbTrace] and [dbTraceSync].
  void _logTraceResult<T>({
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
    required int? itemsCountFromLength,
    required int? affectedOverride,
    required Object? Function(T value)? projectResult,
    required T Function() getResult,
  }) {
    if (!hasActiveConsumers) return;
    guardDiagnostics(this, what: 'Database trace capture', () {
      final resolvedConfig = _resolveResourceConfig(config);
      final success = err == null;
      if (!resolvedConfig.shouldLog(isError: !success, localSample: sample)) {
        return;
      }
      final items = _safeItemCount(
        success,
        itemsCountFromLength,
        getResult,
      );
      if (!hasActiveConsumers) return;
      final projected = _safeProject(success, projectResult, getResult);
      if (!hasActiveConsumers) return;
      final resolvedTarget = target ??
          DbSqlDigest.tableOf(
            statement,
            resourceLimits: resolvedConfig.resourceLimits!,
          );
      final preprocessInput = DbPreprocessInput(
        cfg: resolvedConfig,
        statement: statement,
        args: args,
        namedArgs: namedArgs,
        table: resolvedTarget,
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
      final preprocessed = _preprocessDb(
        preprocessInput,
        errorStackTrace: st,
      );
      _emitDbTrace(
        resolvedConfig: resolvedConfig,
        traceConfig: _resolveTraceConfig(
          resolvedConfig,
          redact: redact,
          redactKeys: redactKeys,
        ),
        shouldRedact: preprocessInput.shouldRedact,
        source: source,
        operation: operation,
        target: resolvedTarget,
        success: success,
        preprocessed: preprocessed,
        duration: elapsed,
        transactionId: txnId,
        sizeBytes: sizeBytes,
        cacheHit: cacheHit,
      );
    });
  }

  static String _buildDbConsoleMessage({
    required String operation,
    required String? table,
    required String? key,
    required Map<String, Object?>? meta,
    required int? sizeBytes,
    required bool? cacheHit,
    required bool success,
  }) =>
      DbMessageFormatter.build(
        operation: operation,
        table: table,
        statement: _metaString(meta, DbLogKeys.statement),
        key: key,
        items: _metaInt(meta, DbLogKeys.items),
        affected: _metaInt(meta, DbLogKeys.affected),
        sizeBytes: sizeBytes,
        cacheHit: cacheHit,
        success: success ? null : false,
      );

  static String? _metaString(Map<String, Object?>? meta, String key) {
    final value = meta?[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Reads [key] from the redacted meta, falling back to the projected result
  /// map so a `projectResult` returning `{'affected': n}` still reports it.
  static int? _metaInt(Map<String, Object?>? meta, String key) {
    final direct = meta?[key];
    if (direct is int) return direct;
    final projected = meta?[DbLogKeys.value];
    if (projected is Map) {
      final nested = projected[key];
      if (nested is int) return nested;
    }
    return null;
  }

  /// Safely project a result value, returning null on failure.
  Object? _safeProject<T>(
    bool success,
    Object? Function(T value)? projectResult,
    T Function() getResult,
  ) {
    if (!success || projectResult == null) return null;
    try {
      return projectResult(getResult());
    } catch (_) {
      log(
        'dbTrace: projection callback failed safely.',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  static int? _safeItemCount<T>(
    bool success,
    int? explicitCount,
    T Function() getResult,
  ) {
    if (!success) return null;
    if (explicitCount != null) return explicitCount;
    try {
      final result = getResult();
      return result is List ? result.length : null;
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
  }) {
    if (!hasActiveConsumers) return _inertDbToken;
    return ISpectDbToken(
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
  }

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
    if (identical(token, _inertDbToken) || !hasActiveConsumers) return;
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
      meta: _mergeBoundedMeta(
        token.meta,
        meta,
        shouldRedact: resolveDbRedact(config),
        resourceLimits: config.resourceLimits ?? options.resourceLimits,
      ),
      transactionId: token.transactionId,
      config: config,
    );
  }

  /// Runs [run] inside a transaction zone. Delegates to [traceTransaction].
  Future<T> dbTransaction<T>({
    required Future<T> Function() run,
    String source = dbDefaultSource,
    @Deprecated(
      'Ignored by transaction markers; pass meta to the db calls inside run. '
      'Will be removed in 8.0.0.',
    )
    Map<String, Object?>? meta,
    bool? logMarkers,
    ISpectDbConfig config = const ISpectDbConfig(),
  }) async {
    if (!hasActiveConsumers) return run();
    final enableMarkers = logMarkers ?? config.enableTransactionMarkers;
    return traceTransaction(
      category: dbCategory,
      source: source,
      run: run,
      logMarkers: enableMarkers,
    );
  }

  ISpectDbConfig _resolveResourceConfig(ISpectDbConfig config) {
    final resourceLimits = (config.resourceLimits ?? options.resourceLimits)
      ..validate();
    return identical(resourceLimits, config.resourceLimits)
        ? config
        : config.copyWith(resourceLimits: resourceLimits);
  }

  /// Preprocesses DB-specific fields into a meta map for trace().
  static _PreprocessedDbTrace _preprocessDb(
    DbPreprocessInput input, {
    StackTrace? errorStackTrace,
  }) {
    final shouldRedact = input.shouldRedact;
    final resourceLimits = input.cfg.resourceLimits!..validate();
    final sensitiveKeys = _boundSensitiveKeys(
      input.sensitiveKeys,
      resourceLimits,
    );
    final diagnostics = _boundDbDiagnostics(
      input,
      errorStackTrace: errorStackTrace,
    );
    final rawErrorText = _renderBoundedDbValue(
      diagnostics.error,
      shouldRedact: shouldRedact,
      resourceLimits: resourceLimits,
    );
    final redactor = _dbRedactor(input, sensitiveKeys);
    final safeKey = _safeDbKey(
      input.key,
      redactor: redactor,
      resourceLimits: resourceLimits,
    );
    final boundedMeta = LogExportOutput.boundJsonValue(
      _buildDbMeta(
        input,
        diagnostics,
        sensitiveKeys: sensitiveKeys,
        redactor: redactor,
        safeKey: safeKey,
        rawErrorText: rawErrorText,
      ),
      maxBytes: resourceLimits.maxDatabaseMetadataBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: shouldRedact,
    );
    return _PreprocessedDbTrace(
      meta: boundedMeta is Map<String, Object?>
          ? boundedMeta
          : const <String, Object?>{},
      key: safeKey,
      error: rawErrorText,
      errorStackTrace: diagnostics.errorStackTraceText == null
          ? null
          : StackTrace.fromString(diagnostics.errorStackTraceText!),
    );
  }

  static Map<String, Object?> _buildDbMeta(
    DbPreprocessInput input,
    _BoundedDbDiagnostics diagnostics, {
    required Set<String> sensitiveKeys,
    required RedactionService? redactor,
    required String? safeKey,
    required String? rawErrorText,
  }) {
    final shouldRedact = input.shouldRedact;
    final resourceLimits = input.cfg.resourceLimits!;
    final maxArgsLen = _boundConfiguredLength(
      input.resolvedMaxArgsLength,
      resourceLimits,
    );
    final boundedStatement = _boundNullableDbText(
      input.statement,
      shouldRedact: shouldRedact,
      maxBytes: resourceLimits.maxDatabaseDiagnosticsBytes,
      resourceLimits: resourceLimits,
    );

    Object? redactData(Object? data, {String? keyName}) {
      if (data == null || redactor == null) return data;
      return redactor.redact(data, keyName: keyName);
    }

    final maxStatementLen = _boundConfiguredLength(
      input.resolvedMaxStatementLength,
      resourceLimits,
    );

    final processedArgs = _processPositionalArgs(
      diagnostics.args,
      redactor: redactor,
      sensitiveKeys: sensitiveKeys,
      statement: boundedStatement,
      maxLen: maxArgsLen,
    );

    final processedNamedArgs = _processNamedArgs(
      redactData(diagnostics.namedArgs),
      maxLen: maxArgsLen,
    );

    final processedMeta = redactData(diagnostics.meta);
    final digest = DbSqlDigest.compute(
      boundedStatement,
      resourceLimits: resourceLimits,
    );
    final normalizedStmt = DbSqlDigest.normalize(
          boundedStatement,
          resourceLimits: resourceLimits,
        ) ??
        digest;

    final truncatedValue = ISpectDbCore.truncateValue(
      redactData(diagnostics.value, keyName: input.key),
      _boundConfiguredLength(
        input.resolvedMaxValueLength,
        resourceLimits,
      ),
    );

    final errorText = rawErrorText == null
        ? null
        : redactor == null
            ? rawErrorText
            : _redactDbError(
                rawErrorText,
                redactor,
                resourceLimits,
              );

    return ISpectDbCore.clean(<String, Object?>{
      DbLogKeys.statementDigest: digest,
      DbLogKeys.statement: _truncateToString(
        shouldRedact ? normalizedStmt : boundedStatement,
        maxStatementLen,
      ),
      if (input.table != null)
        DbLogKeys.table: _boundDbText(
          input.table!,
          shouldRedact: shouldRedact,
          resourceLimits: resourceLimits,
        ),
      if (safeKey != null) DbLogKeys.key: safeKey,
      DbLogKeys.args: processedArgs,
      DbLogKeys.namedArgs: processedNamedArgs,
      if (input.affected != null) DbLogKeys.affected: input.affected,
      if (input.items != null) DbLogKeys.items: input.items,
      if (input.sizeBytes != null) DbLogKeys.sizeBytes: input.sizeBytes,
      if (input.cacheHit != null) DbLogKeys.cacheHit: input.cacheHit,
      if (truncatedValue != null) DbLogKeys.value: truncatedValue,
      if (processedMeta != null) DbLogKeys.userMeta: processedMeta,
      if (errorText != null) DbLogKeys.dbError: errorText,
    });
  }

  static RedactionService? _dbRedactor(
    DbPreprocessInput input,
    Set<String> sensitiveKeys,
  ) {
    if (!input.shouldRedact) return null;
    if (!input.hasExplicitRedactKeys) return ISpectRedaction.service;
    return RedactionService(
      sensitiveKeys: sensitiveKeys,
      placeholder: defaultPlaceholder,
    );
  }

  static String? _truncateToString(String? value, int maxLen) {
    if (value == null) return null;
    final truncated = ISpectDbCore.truncateValue(value, maxLen);
    return truncated is String ? truncated : truncated?.toString();
  }

  static String? _safeDbKey(
    String? key, {
    required RedactionService? redactor,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (key == null) return null;
    final bounded = _boundDbText(
      key,
      shouldRedact: redactor != null,
      resourceLimits: resourceLimits,
    );
    if (redactor == null) return bounded;
    if (_isSensitiveDbKeyName(bounded, redactor) ||
        _dbKeyEmailPattern.hasMatch(bounded) ||
        _embedsIdentifierNumber(bounded) ||
        _hasSensitiveDbKeySegment(bounded, redactor)) {
      return defaultPlaceholder;
    }
    final scrubbed = redactor.redactForExport(
      bounded,
      resourceLimits: resourceLimits,
    );
    return scrubbed == bounded ? bounded : defaultPlaceholder;
  }

  static bool _isSensitiveDbKeyName(String name, RedactionService redactor) {
    final keyProbe = redactor.redact(<String, Object?>{name: _dbKeyProbe});
    return keyProbe is! Map || keyProbe[name] != _dbKeyProbe;
  }

  static bool _hasSensitiveDbKeySegment(
    String key,
    RedactionService redactor,
  ) {
    final segments = key.split(_dbKeySegmentDelimiters);
    if (segments.length < 2) return _isOpaqueOrPhoneDbKeySegment(key);
    for (final segment in segments) {
      if (segment.isEmpty) continue;
      if (_dbKeyCredentialNamespaces.contains(segment.toLowerCase()) ||
          _isOpaqueOrPhoneDbKeySegment(segment) ||
          _isSensitiveDbKeyName(segment, redactor)) {
        return true;
      }
    }
    return false;
  }

  static bool _embedsIdentifierNumber(String key) =>
      _dbKeyDigitSequence.allMatches(key.replaceAll(_dbKeyIsoDate, '_')).any(
            (match) =>
                match[0]!.replaceAll(_dbKeyNonDigit, '').length >=
                _dbKeyMinIdentifierDigits,
          );

  static bool _isOpaqueOrPhoneDbKeySegment(String segment) {
    if (_dbKeyPhoneSegment.hasMatch(segment)) return true;
    return _dbKeyOpaqueSegment.hasMatch(segment) &&
        _dbKeyMixedRun.hasMatch(segment);
  }

  static String _redactDbError(
    String error,
    RedactionService redactor,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final redacted = redactor.redactForExport(
      error,
      resourceLimits: resourceLimits,
    );
    return redacted is String ? redacted : defaultPlaceholder;
  }

  static ISpectDbConfig _resolveTraceConfig(
    ISpectDbConfig config, {
    required bool? redact,
    required List<String>? redactKeys,
  }) {
    final resolvedRedact = resolveDbRedact(config, redact: redact);
    final usesDefaultKeys = redactKeys == null &&
        identical(config.redactKeys, defaultSensitiveKeys);
    final resolvedKeys = usesDefaultKeys
        ? config.redactKeys
        : _boundSensitiveKeys(
            redactKeys ?? config.redactKeys,
            config.resourceLimits!,
          );
    if (resolvedRedact == config.redact &&
        identical(resolvedKeys, config.redactKeys) &&
        config.errorSampleRate >= 1) {
      return config;
    }
    return config.copyWith(
      redact: resolvedRedact,
      redactKeys: resolvedKeys,
      errorSampleRate: 1,
    );
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

  static _BoundedDbDiagnostics _boundDbDiagnostics(
    DbPreprocessInput input, {
    required StackTrace? errorStackTrace,
  }) {
    final shouldRedact = input.shouldRedact;
    final resourceLimits = input.cfg.resourceLimits!;
    final bounded = LogExportOutput.boundJsonValue(
      <String, Object?>{
        if (input.error != null) 'error': input.error,
        if (errorStackTrace != null) 'errorStackTrace': errorStackTrace,
        if (input.args != null) 'args': input.args,
        if (input.namedArgs != null) 'namedArgs': input.namedArgs,
        if (input.value != null) 'value': input.value,
        if (input.meta != null) 'meta': input.meta,
      },
      maxBytes: resourceLimits.maxDatabaseDiagnosticsBytes,
      resourceLimits: resourceLimits,
      preserveTypes: shouldRedact,
      replaceOversizedStrings: shouldRedact,
      allowCustomSerialization:
          input.cfg.captureMode == DiagnosticCaptureMode.balanced,
      allowCustomStringification:
          input.cfg.captureMode == DiagnosticCaptureMode.balanced,
    );
    final values =
        bounded is Map<String, Object?> ? bounded : const <String, Object?>{};

    return _BoundedDbDiagnostics(
      args: switch (values['args']) {
        final List<Object?> value => List<Object?>.unmodifiable(value),
        _ => null,
      },
      namedArgs: switch (values['namedArgs']) {
        final Map<String, Object?> value =>
          Map<String, Object?>.unmodifiable(value),
        _ => null,
      },
      value: values['value'],
      meta: switch (values['meta']) {
        final Map<String, Object?> value =>
          Map<String, Object?>.unmodifiable(value),
        _ => null,
      },
      error: values['error'],
      errorStackTraceText: switch (values['errorStackTrace']) {
        final String value => value,
        _ => null,
      },
    );
  }

  static Set<String> _boundSensitiveKeys(
    Iterable<String> values,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final bounded = LogExportOutput.boundJsonValue(
      values,
      maxBytes: resourceLimits.maxDatabaseDiagnosticsBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: true,
    );
    if (bounded is! List<Object?>) return defaultSensitiveKeys;
    final result = <String>{};
    var traversalFailed = false;
    for (final value in bounded) {
      if (value is! String) {
        traversalFailed = true;
        continue;
      }
      if (value == JsonValueNormalizer.unprintableValue ||
          value == JsonValueNormalizer.maxNodesReached ||
          value == LogExportOutput.truncatedMarker) {
        traversalFailed = true;
        continue;
      }
      if (value == JsonValueNormalizer.maxCollectionItemsReached) break;
      result.add(value);
    }
    return traversalFailed && result.isEmpty ? defaultSensitiveKeys : result;
  }

  static int _boundConfiguredLength(
    int value,
    DiagnosticResourceLimits resourceLimits,
  ) =>
      value.clamp(
        0,
        resourceLimits.maxDatabaseDiagnosticsBytes,
      );

  static String? _renderBoundedDbValue(
    Object? value, {
    required bool shouldRedact,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (value == null) return null;
    final bounded = LogExportOutput.boundJsonValue(
      value,
      replaceOversizedStrings: shouldRedact,
      resourceLimits: resourceLimits,
    );
    if (bounded is String) return bounded;
    if (bounded is bool || bounded is num) return Error.safeToString(bounded);
    try {
      final encoded = jsonEncode(bounded);
      if (LogExportOutput.utf8Length(
            encoded,
            limit: resourceLimits.maxDatabaseDiagnosticsBytes,
          ) <=
          resourceLimits.maxDatabaseDiagnosticsBytes) {
        return encoded;
      }
      return shouldRedact
          ? LogExportOutput.truncatedMarker
          : LogExportOutput.truncateUtf8(
              encoded,
              maxBytes: resourceLimits.maxDatabaseDiagnosticsBytes,
            );
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  static String _boundDbText(
    String value, {
    required bool shouldRedact,
    required DiagnosticResourceLimits resourceLimits,
    int? maxBytes,
  }) {
    final bounded = LogExportOutput.boundJsonValue(
      value,
      maxBytes: maxBytes ?? resourceLimits.maxDatabaseScalarBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: shouldRedact,
    );
    return bounded is String ? bounded : JsonValueNormalizer.unprintableValue;
  }

  static String? _boundNullableDbText(
    String? value, {
    required bool shouldRedact,
    required DiagnosticResourceLimits resourceLimits,
    int? maxBytes,
  }) =>
      value == null
          ? null
          : _boundDbText(
              value,
              shouldRedact: shouldRedact,
              resourceLimits: resourceLimits,
              maxBytes: maxBytes,
            );

  static Map<String, Object?>? _mergeBoundedMeta(
    Map<String, Object?>? first,
    Map<String, Object?>? second, {
    required bool shouldRedact,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (first == null && second == null) return null;
    final bounded = LogExportOutput.boundJsonValue(
      <String, Object?>{
        if (first != null) 'first': first,
        if (second != null) 'second': second,
      },
      maxBytes: resourceLimits.maxDatabaseDiagnosticsBytes,
      resourceLimits: resourceLimits,
      preserveTypes: shouldRedact,
      replaceOversizedStrings: shouldRedact,
    );
    if (bounded is! Map<String, Object?>) return null;
    final firstValues = bounded['first'];
    final secondValues = bounded['second'];
    return <String, Object?>{
      if (firstValues is Map<String, Object?>) ...firstValues,
      if (secondValues is Map<String, Object?>) ...secondValues,
    };
  }
}

final class _DbProjectionNotProvided {
  const _DbProjectionNotProvided();
}

final class _BoundedDbDiagnostics {
  const _BoundedDbDiagnostics({
    required this.args,
    required this.namedArgs,
    required this.value,
    required this.meta,
    required this.error,
    required this.errorStackTraceText,
  });

  final List<Object?>? args;
  final Map<String, Object?>? namedArgs;
  final Object? value;
  final Map<String, Object?>? meta;
  final Object? error;
  final String? errorStackTraceText;
}

final class _PreprocessedDbTrace {
  const _PreprocessedDbTrace({
    required this.meta,
    required this.key,
    required this.error,
    required this.errorStackTrace,
  });

  final Map<String, Object?> meta;
  final String? key;
  final String? error;
  final StackTrace? errorStackTrace;
}
