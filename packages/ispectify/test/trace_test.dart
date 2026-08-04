// ignore_for_file: cascade_invocations, avoid_redundant_argument_values, prefer_const_declarations, prefer_int_literals

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/trace/trace_helpers.dart';
import 'package:ispectify/src/trace/trace_message.dart';
import 'package:test/test.dart';

final class _CheckStatusAuthEvent {
  const _CheckStatusAuthEvent();
}

final class _RecordingObserver implements ISpectObserver {
  ISpectLogData? lastLog;

  @override
  void onError(ISpectLogData data) => lastLog = data;

  @override
  void onException(ISpectLogData data) => lastLog = data;

  @override
  void onLog(ISpectLogData data) => lastLog = data;
}

final class _HostileTraceException implements Exception {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_TRACE_EXCEPTION');
  }
}

final class _HostileTraceStack implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_TRACE_STACK');
  }
}

final class _HostileTraceValue {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    throw StateError('HOSTILE_TRACE_TO_JSON');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_TRACE_TO_STRING');
  }
}

final class _ReadableTraceValue {
  int toJsonCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    return const {
      'label': 'ready',
      'password': 'TRACE_TYPED_SECRET',
    };
  }
}

final class _ThrowingTraceMeta extends MapBase<String, Object?> {
  int keyReads = 0;

  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(String key, Object? value) {}

  @override
  void clear() {}

  @override
  Iterable<String> get keys {
    keyReads++;
    throw StateError('HOSTILE_TRACE_META_ITERATOR');
  }

  @override
  Object? remove(Object? key) => null;
}

void main() {
  // ── ISpectTraceCategory ──────────────────────────────────────────
  group('ISpectTraceCategory.pickLogKey', () {
    test('returns errorKey when isError=true', () {
      expect(
        networkCategory.pickLogKey(isError: true, operation: 'GET'),
        equals('http-error'),
      );
    });

    test('returns secondaryKey for matching operation', () {
      expect(
        networkCategory.pickLogKey(isError: false, operation: 'GET'),
        equals('http-request'),
      );
    });

    test('returns successKey for non-matching operation', () {
      expect(
        networkCategory.pickLogKey(isError: false, operation: 'POST'),
        equals('http-response'),
      );
    });
  });

  // ── ISpectTraceConfig ────────────────────────────────────────────
  group('ISpectTraceConfig.shouldLog', () {
    test('null sampleRate logs everything', () {
      const cfg = ISpectTraceConfig();
      expect(cfg.shouldLog(isError: false), isTrue);
    });

    test('sampleRate 0.0 suppresses non-error logs', () {
      const cfg = ISpectTraceConfig(sampleRate: 0);
      expect(cfg.shouldLog(isError: false), isFalse);
    });

    test('errorSampleRate always used for errors', () {
      const cfg = ISpectTraceConfig(sampleRate: 0, errorSampleRate: 1);
      expect(cfg.shouldLog(isError: true), isTrue);
    });

    test('localSample overrides config sampleRate', () {
      const cfg = ISpectTraceConfig(sampleRate: 0);
      expect(cfg.shouldLog(isError: false, localSample: 1), isTrue);
    });

    test('copyWith preserves and replaces per-trace resource limits', () {
      const limits = DiagnosticResourceLimits.constrained;
      const replacement = DiagnosticResourceLimits.extended;
      const config = ISpectTraceConfig(resourceLimits: limits);

      expect(config.copyWith().resourceLimits, same(limits));
      expect(
        config.copyWith(resourceLimits: replacement).resourceLimits,
        same(replacement),
      );
      expect(
        config
            .copyWith(
              resourceLimits: replacement,
              inheritResourceLimits: true,
            )
            .resourceLimits,
        isNull,
      );
    });
  });

  // ── buildTraceMessage ────────────────────────────────────────────
  group('buildTraceMessage', () {
    test('includes all fields', () {
      final msg = buildTraceMessage(
        operation: 'GET',
        success: true,
        target: '/api/users',
        key: 'id-123',
      );
      expect(
        msg,
        isNot(contains('[dio]')),
        reason: 'source belongs to entry header, not body',
      );
      expect(
        msg,
        isNot(contains('ms')),
        reason: 'duration belongs to metadata (dur=…ms), not body',
      );
      expect(
        msg,
        contains('→ GET /api/users'),
        reason: 'method + URL render as a single block on the second line',
      );
      expect(msg, contains('(id-123)'));
      expect(msg, isNot(contains('FAILED')));
    });

    test('shows FAILED for unsuccessful', () {
      final msg = buildTraceMessage(
        operation: 'POST',
        success: false,
      );
      expect(msg, contains('FAILED'));
    });
  });

  // ── trace() via FakeISpectLogger ─────────────────────────────────
  group('trace() fire-and-forget', () {
    late FakeISpectLogger logger;

    setUp(() => logger = FakeISpectLogger());
    tearDown(ISpectRedaction.reset);

    test('creates log with correct structure', () {
      logger.trace(
        category: dbCategory,
        source: 'drift',
        operation: 'insert',
        target: 'users',
        success: true,
        duration: const Duration(milliseconds: 5),
      );

      expect(logger.traces, hasLength(1));
      final log = logger.traces.first;
      expect(log.key, equals('db-result'));
      expect(log.additionalData?[TraceKeys.category], 'db');
      expect(log.additionalData?[TraceKeys.source], 'drift');
      expect(log.additionalData?[TraceKeys.operation], 'insert');
      expect(log.additionalData?[TraceKeys.target], 'users');
      expect(log.additionalData?[TraceKeys.durationMs], 5);
      expect(log.additionalData?[TraceKeys.success], isTrue);
    });

    test('disabled logger produces no logs', () {
      final disabled = FakeISpectLogger();
      disabled.configure(options: ISpectLoggerOptions(enabled: false));
      disabled.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
      );
      expect(disabled.traces, isEmpty);
    });

    test('inherits resource limits from logger options', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 64,
        maxLogRecordBytes: 256,
        maxExportDocumentBytes: 512,
      );
      logger.configure(
        options: logger.options.copyWith(resourceLimits: limits),
      );

      logger.trace(
        category: dbCategory,
        source: 's' * 200,
        operation: 'read',
        config: const ISpectTraceConfig(redact: false),
      );

      final source =
          '${logger.traces.single.additionalData?[TraceKeys.source]}';
      expect(
        LogExportOutput.utf8Length(source),
        lessThanOrEqualTo(limits.maxCapturedValueBytes),
      );
    });

    test('per-trace resource limits override the logger policy', () {
      final loggerLimits = DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 64,
        maxLogRecordBytes: 256,
        maxExportDocumentBytes: 512,
      );
      final traceLimits = loggerLimits.copyWith(
        maxCapturedValueBytes: 512,
        maxLogRecordBytes: 1024,
        maxExportDocumentBytes: 2048,
      );
      logger.configure(
        options: logger.options.copyWith(resourceLimits: loggerLimits),
      );

      logger.trace(
        category: dbCategory,
        source: 's' * 200,
        operation: 'read',
        config: ISpectTraceConfig(
          redact: false,
          resourceLimits: traceLimits,
        ),
      );

      final source =
          '${logger.traces.single.additionalData?[TraceKeys.source]}';
      expect(
        LogExportOutput.utf8Length(source),
        greaterThan(loggerLimits.maxCapturedValueBytes),
      );
      expect(
        LogExportOutput.utf8Length(source),
        lessThanOrEqualTo(traceLimits.maxCapturedValueBytes),
      );
    });

    test('disposed logger does not inspect trace metadata', () async {
      final disposed = FakeISpectLogger();
      final meta = _ThrowingTraceMeta();
      await disposed.dispose();

      disposed.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        meta: meta,
      );

      expect(meta.keyReads, 0);
      expect(disposed.traces, isEmpty);
    });

    test('logKey override works', () {
      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        logKey: ISpectLogType.httpRequest.key,
      );
      expect(logger.traces.first.key, 'http-request');
    });

    test('redacts sensitive keys in the value field by default', () {
      logger.trace(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        value: const {'password': 'hunter2', 'id': 7},
      );
      final value = logger.traces.first.additionalData?[TraceKeys.value];
      expect('$value', isNot(contains('hunter2')));
      expect('$value', contains('[REDACTED]'));
    });

    test('uses the configured global service by default', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'business_marker'},
          placeholder: '<GLOBAL_POLICY>',
        ),
      );

      logger.trace(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        value: const {'business_marker': 'trace-secret'},
      );

      final value = logger.traces.first.additionalData?[TraceKeys.value];
      expect('$value', isNot(contains('trace-secret')));
      expect('$value', contains('<GLOBAL_POLICY>'));
    });

    test('explicit trace keys take precedence over the global service', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'global_marker'},
          placeholder: '<GLOBAL_POLICY>',
        ),
      );

      logger.trace(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        value: const {
          'local_marker': 'local-secret',
          'global_marker': 'global-visible',
        },
        config: const ISpectTraceConfig(
          redactKeys: {'local_marker'},
        ),
      );

      final value = logger.traces.first.additionalData?[TraceKeys.value];
      expect('$value', isNot(contains('local-secret')));
      expect('$value', contains(defaultPlaceholder));
      expect('$value', contains('global-visible'));
      expect('$value', isNot(contains('<GLOBAL_POLICY>')));
    });

    test('redacts sensitive URL params in the error string by default', () {
      logger.trace(
        category: networkCategory,
        source: 'ws',
        operation: 'connect',
        error: "WebSocketException: connection to 'wss://h/ws?token=SECRETTOK'",
      );
      final error = logger.traces.first.additionalData?[TraceKeys.error];
      expect('$error', isNot(contains('SECRETTOK')));
      expect('$error', contains('token=[REDACTED]'));
    });

    test('keeps pre-redacted tokens stable in colon-form error prose', () {
      logger.trace(
        category: dbCategory,
        source: 'postgres',
        operation: 'query',
        error: 'auth failed: Bearer [REDACTED] '
            'via postgres://REDACTED@db.example.com',
      );

      final error = '${logger.traces.first.additionalData?[TraceKeys.error]}';
      expect(error, contains('Bearer [REDACTED]'));
      expect(error, isNot(contains('[R…ED ([REDACTED])]')));
    });

    test('still redacts sensitive colon-form assignments', () {
      logger.trace(
        category: dbCategory,
        source: 'postgres',
        operation: 'query',
        meta: const {'detail': 'password: hunter2, safe: visible'},
      );

      final detail = logger.traces.first.traceMeta?['detail'].toString();
      expect(detail, contains('password: [REDACTED]'));
      expect(detail, isNot(contains('hunter2')));
      expect(detail, contains('safe: visible'));
    });

    test('does not retain the raw exception when redaction is enabled', () {
      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        error: Exception(
          'failed https://api.example.test/users?token=TRACE_SECRET',
        ),
      );

      final log = logger.traces.single;

      expect(
        '${log.additionalData?[TraceKeys.error]}',
        isNot(contains('TRACE_SECRET')),
      );
      expect('${log.exception}', isNot(contains('TRACE_SECRET')));
      expect(log.textMessage, isNot(contains('TRACE_SECRET')));
    });

    test('sanitizes caller-controlled structured fields before observers', () {
      const correlationId = 'tenantSecret=CORRELATION_IDENTIFIER';
      final observer = _RecordingObserver();
      final historyLogger = ISpectLogger.testing(
        observer: observer,
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      historyLogger.trace(
        category: dbCategory,
        source: 'client?token=SOURCE_SECRET',
        operation: 'tenantSecret=OPERATION_SECRET',
        key: 'tenantSecret=KEY_SECRET',
        logKey: 'custom?token=LOG_KEY_SECRET',
        correlationId: correlationId,
        error: Exception('tenantSecret=ERROR_SECRET'),
        errorStackTrace: StackTrace.fromString(
          'tenantSecret=STACK_SECRET',
        ),
        config: const ISpectTraceConfig(
          redactKeys: {'token', 'tenantSecret'},
          attachStackOnError: true,
        ),
      );

      final log = historyLogger.history.single;
      final serialized = <Object?>[
        log.key,
        log.message,
        log.additionalData,
        log.exception,
        log.error,
        log.stackTrace,
      ].join('\n');

      expect(serialized, isNot(contains('SOURCE_SECRET')));
      expect(serialized, isNot(contains('OPERATION_SECRET')));
      expect(serialized, isNot(contains('KEY_SECRET')));
      expect(serialized, isNot(contains('LOG_KEY_SECRET')));
      expect(serialized, isNot(contains('ERROR_SECRET')));
      expect(serialized, isNot(contains('STACK_SECRET')));
      expect(
        log.additionalData?[TraceKeys.correlationId],
        'tenantSecret=[REDACTED]',
        reason: 'Caller-controlled grouping identifiers follow trace policy.',
      );
      expect(observer.lastLog, same(log));
    });

    test('sanitizes a caller-defined category identifier', () {
      const category = ISpectTraceCategory(
        id: 'tenantSecret=CATEGORY_SECRET',
        successKey: 'custom-success',
        errorKey: 'custom-error',
      );

      logger.trace(
        category: category,
        source: 'test',
        operation: 'run',
        config: const ISpectTraceConfig(
          redactKeys: {'tenantSecret'},
        ),
      );

      expect(
        logger.traces.single.additionalData?[TraceKeys.category],
        'tenantSecret=[REDACTED]',
      );
    });

    test('retains bounded ordinary error text for an explicit opt-out', () {
      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        error: 'token=TRACE_RAW',
        config: const ISpectTraceConfig(redact: false),
      );

      expect(
        logger.traces.single.additionalData?[TraceKeys.error],
        'token=TRACE_RAW',
      );
    });

    test('bounds opt-out diagnostics without executing their formatters', () {
      logger.configure(
        options: logger.options.copyWith(
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );
      final exception = _HostileTraceException();
      final stack = _HostileTraceStack();

      logger.trace(
        category: networkCategory,
        source: 's' * (4 * 1024 * 1024),
        operation: 'GET',
        error: exception,
        errorStackTrace: stack,
        config: const ISpectTraceConfig(
          redact: false,
          attachStackOnError: true,
        ),
      );

      final log = logger.traces.single;
      expect(exception.calls, 0);
      expect(stack.calls, 0);
      expect(
        LogExportOutput.utf8Length(
          '${log.additionalData?[TraceKeys.source]}',
        ),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect('${log.exception}', isNot(contains('HOSTILE_')));
    });

    test('bounds diagnostics before redaction without executing formatters',
        () {
      logger.configure(
        options: logger.options.copyWith(
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );
      final exception = _HostileTraceException();
      final stack = _HostileTraceStack();
      final value = _HostileTraceValue();

      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        value: value,
        error: exception,
        errorStackTrace: stack,
        meta: {'payload': 'p' * (4 * 1024 * 1024)},
        config: const ISpectTraceConfig(attachStackOnError: true),
      );

      final log = logger.traces.single;
      expect(
        LogExportOutput.utf8Length(
          log.additionalData.toString(),
          limit: LogExportOutput.maxRecordBytes,
        ),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
      expect(exception.calls, 0);
      expect(stack.calls, 0);
      expect(value.toJsonCalls, 0);
      expect(value.toStringCalls, 0);
    });

    test('balanced mode captures and redacts typed trace values', () {
      final value = _ReadableTraceValue();

      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        value: value,
      );

      expect(
        logger.traces.single.additionalData?[TraceKeys.value],
        {
          'label': 'ready',
          'password': '[REDACTED]',
        },
      );
      expect(value.toJsonCalls, 1);
    });
  });

  // ── traceAsync ───────────────────────────────────────────────────
  group('traceAsync', () {
    late FakeISpectLogger logger;

    setUp(() => logger = FakeISpectLogger());

    test('returns result and logs success', () async {
      final result = await logger.traceAsync(
        category: dbCategory,
        source: 'sqflite',
        operation: 'query',
        run: () async => 42,
      );

      expect(result, 42);
      expect(logger.traces, hasLength(1));
      expect(logger.traces.first.additionalData?[TraceKeys.success], isTrue);
    });

    test('rethrows and logs error', () async {
      await expectLater(
        () => logger.traceAsync(
          category: dbCategory,
          source: 'sqflite',
          operation: 'insert',
          run: () async => throw StateError('fail'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(logger.traces, hasLength(1));
      expect(logger.traces.first.additionalData?[TraceKeys.success], isFalse);
    });

    test('projectResult failure still logs', () async {
      final result = await logger.traceAsync(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        run: () async => 'data',
        projectResult: (_) => throw Exception('bad projection'),
      );
      expect(result, 'data');
      expect(logger.byCategory(dbCategory.id), hasLength(1));
    });

    test('projection failure diagnostics do not retain exception text or stack',
        () async {
      const secret = 'tenantSecret=PROJECTION_SECRET';
      final historyLogger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      await historyLogger.traceAsync(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        run: () async => 'data',
        projectResult: (_) => throw StateError(secret),
      );

      final diagnostics = historyLogger.history.join('\n');
      expect(diagnostics, isNot(contains('PROJECTION_SECRET')));
      expect(diagnostics, isNot(contains('trace_test.dart')));
    });

    test('sampling 0.0 executes run but skips log', () async {
      var projectionCalls = 0;
      final result = await logger.traceAsync(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        run: () async => 'ok',
        sample: 0,
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );
      expect(result, 'ok');
      expect(logger.traces, isEmpty);
      expect(projectionCalls, 0);
    });

    test('runtime disablement skips an in-flight result projection', () async {
      var projectionCalls = 0;

      final result = await logger.traceAsync(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        run: () async {
          logger.disable();
          return 'business-result';
        },
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      expect(result, 'business-result');
      expect(projectionCalls, 0);
      expect(logger.traces, isEmpty);
    });
  });

  // ── traceSync ────────────────────────────────────────────────────
  group('traceSync', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('returns result and logs success', () {
      final result = logger.traceSync(
        category: dbCategory,
        source: 'hive',
        operation: 'get',
        run: () => 'value',
      );
      expect(result, 'value');
      expect(logger.traces, hasLength(1));
      expect(logger.traces.first.additionalData?[TraceKeys.success], isTrue);
    });

    test('rethrows on error', () {
      expect(
        () => logger.traceSync(
          category: dbCategory,
          source: 'hive',
          operation: 'put',
          run: () => throw ArgumentError('bad'),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(logger.traces, hasLength(1));
    });

    test('sampling 0.0 skips the result projection', () {
      var projectionCalls = 0;

      final result = logger.traceSync(
        category: dbCategory,
        source: 'hive',
        operation: 'get',
        run: () => 'value',
        sample: 0,
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      expect(result, 'value');
      expect(logger.traces, isEmpty);
      expect(projectionCalls, 0);
    });

    test('runtime disablement skips an in-flight result projection', () {
      var projectionCalls = 0;

      final result = logger.traceSync(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        run: () {
          logger.disable();
          return 'business-result';
        },
        projectResult: (value) {
          projectionCalls++;
          return value;
        },
      );

      expect(result, 'business-result');
      expect(projectionCalls, 0);
      expect(logger.traces, isEmpty);
    });
  });

  // ── traceStart / traceEnd ────────────────────────────────────────
  group('traceStart/traceEnd', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('manual span with duration', () {
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'grpc',
        operation: 'unary',
        target: 'UserService/GetUser',
        meta: const {'shared': 'start', 'base': true},
      );
      expect(token, isNotNull);

      logger.traceEnd(
        token,
        value: 'ok',
        success: true,
        meta: const {'shared': 'end'},
      );
      expect(logger.traces, hasLength(1));
      final log = logger.traces.first;
      expect(log.additionalData?[TraceKeys.durationMs], isNotNull);
      expect(
        log.additionalData?[TraceKeys.meta],
        {'shared': 'end', 'base': true},
      );
    });

    test('sanitizes every retained token field at traceStart', () {
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'password=SOURCE_SECRET',
        operation: 'token=OPERATION_SECRET',
        target:
            'https://user:TARGET_SECRET@example.test/rpc?token=QUERY_SECRET',
        key: 'password=KEY_SECRET',
        meta: const {'password': 'META_SECRET'},
        correlationId: 'token=CORRELATION_SECRET',
      );

      final retained = <Object?>[
        token?.source,
        token?.operation,
        token?.target,
        token?.key,
        token?.meta,
        token?.correlationId,
      ].join('\n');
      for (final secret in const [
        'SOURCE_SECRET',
        'OPERATION_SECRET',
        'TARGET_SECRET',
        'QUERY_SECRET',
        'KEY_SECRET',
        'META_SECRET',
        'CORRELATION_SECRET',
      ]) {
        expect(retained, isNot(contains(secret)));
      }
    });

    test('active redaction drops a previously truncated prefix', () {
      const partial = 'PARTIAL_TRACE_SECRET';
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'grpc',
        operation: 'unary',
        target: '$partial${LogExportOutput.truncatedMarker}',
        meta: const {
          'visible': '$partial${LogExportOutput.truncatedMarker}',
        },
      );

      expect(token?.target, LogExportOutput.truncatedMarker);
      expect(token?.meta?['visible'], LogExportOutput.truncatedMarker);
    });

    test('explicit opt-out retains only a bounded token prefix', () {
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'raw-source',
        operation: 'raw-operation',
        target: 'RAW_TARGET_${'x' * (4 * 1024 * 1024)}',
        config: const ISpectTraceConfig(redact: false),
      );

      expect(token?.target, startsWith('RAW_TARGET_'));
      expect(
        LogExportOutput.utf8Length(token?.target ?? ''),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('bounds start metadata and tolerates a throwing end map', () {
      final hostile = _ThrowingTraceMeta();
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'grpc',
        operation: 'unary',
        meta: {'oversized': 's' * (4 * 1024 * 1024)},
      );

      expect(
        token?.meta?['oversized'],
        LogExportOutput.truncatedMarker,
      );
      expect(
        () => logger.traceEnd(token, meta: hostile),
        returnsNormally,
      );
      expect(hostile.keyReads, greaterThan(0));
      expect(logger.traces, hasLength(1));
      expect(
        jsonEncode(logger.traces.single.additionalData?[TraceKeys.meta]),
        isNot(contains('HOSTILE_TRACE_META_ITERATOR')),
      );
    });

    test('does not inspect end metadata after runtime disablement', () {
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'grpc',
        operation: 'unary',
      );
      final hostile = _ThrowingTraceMeta();
      logger.configure(options: ISpectLoggerOptions(enabled: false));

      logger.traceEnd(token, meta: hostile);

      expect(hostile.keyReads, 0);
      expect(logger.traces, isEmpty);
    });

    test('runtime disablement still stops manual span timing', () async {
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'grpc',
        operation: 'unary',
      )!;
      await Future<void>.delayed(const Duration(milliseconds: 2));

      logger.disable();
      logger.traceEnd(token);
      final stoppedAt = token.elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(token.elapsed, stoppedAt);
      expect(logger.traces, isEmpty);

      logger.enable();
      logger.traceEnd(token);
      expect(logger.traces, hasLength(1));
    });

    test('returns null when disabled', () {
      logger.configure(options: ISpectLoggerOptions(enabled: false));
      final token = logger.traceStart(
        category: grpcCategory,
        source: 'grpc',
        operation: 'unary',
      );
      expect(token, isNull);
      // traceEnd(null) is no-op
      logger.traceEnd(token);
      expect(logger.traces, isEmpty);
    });
  });

  // ── traceStream ──────────────────────────────────────────────────
  group('traceStream', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('logs subscribe, events, unsubscribe', () async {
      final controller = StreamController<int>();
      final traced = logger.traceStream(
        category: wsCategory,
        source: 'ws',
        operation: 'messages',
        stream: controller.stream,
      );

      final collected = <int>[];
      final sub = traced.listen(collected.add);

      controller
        ..add(1)
        ..add(2);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      await controller.close();

      expect(collected, [1, 2]);
      // subscribe + 2 events + unsubscribe = 4 logs
      expect(logger.traces.length, 4);
      // All share same correlationId
      final corrIds = logger.traces
          .map((l) => l.additionalData?[TraceKeys.correlationId])
          .toSet();
      expect(corrIds, hasLength(1));
    });

    test('sampling 0.0 skips event projections', () async {
      var projectionCalls = 0;
      final traced = logger.traceStream(
        category: wsCategory,
        source: 'ws',
        operation: 'messages',
        stream: Stream<int>.value(1),
        sample: 0,
        projectEvent: (value) {
          projectionCalls++;
          return value;
        },
      );

      await traced.drain<void>();

      expect(projectionCalls, 0);
      expect(
        logger.traces.where(
          (log) => log.traceOperation == 'messages.event',
        ),
        isEmpty,
      );
    });

    test('runtime disablement skips event projection but preserves data',
        () async {
      final controller = StreamController<int>();
      var projectionCalls = 0;
      final collected = <int>[];
      final traced = logger.traceStream(
        category: wsCategory,
        source: 'ws',
        operation: 'messages',
        stream: controller.stream,
        projectEvent: (value) {
          projectionCalls++;
          return value;
        },
      );
      final subscription = traced.listen(collected.add);

      logger.disable();
      controller.add(7);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await controller.close();

      expect(collected, [7]);
      expect(projectionCalls, 0);
      expect(
        logger.traces.where(
          (log) => log.traceOperation == 'messages.event',
        ),
        isEmpty,
      );
    });
  });

  // ── traceTransaction ─────────────────────────────────────────────
  group('traceTransaction', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('auto-injects transactionId', () async {
      await logger.traceTransaction(
        category: dbCategory,
        source: 'drift',
        run: () async {
          logger.trace(
            category: dbCategory,
            source: 'drift',
            operation: 'insert',
          );
          logger.trace(
            category: dbCategory,
            source: 'drift',
            operation: 'update',
          );
        },
      );

      expect(logger.traces, hasLength(2));
      final txnIds = logger.traces
          .map((l) => l.additionalData?[TraceKeys.transactionId])
          .toSet();
      expect(txnIds, hasLength(1));
      expect(txnIds.first, isNotNull);
    });

    test('disabled transaction executes directly in the caller zone', () async {
      logger.configure(options: ISpectLoggerOptions(enabled: false));
      final callerZone = Zone.current;
      Zone? runZone;

      final result = await logger.traceTransaction(
        category: dbCategory,
        source: 'drift',
        run: () async {
          runZone = Zone.current;
          return 42;
        },
      );

      expect(result, 42);
      expect(identical(runZone, callerZone), isTrue);
      expect(logger.traces, isEmpty);
    });
  });

  // ── wsState (ws-state key) ───────────────────────────────────────
  group('wsSend / wsReceive', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('wsSend pins the ws-sent key regardless of operation', () {
      logger.wsSend(source: 'ws', operation: 'anything');
      expect(logger.lastTrace!.key, ISpectLogType.wsSent.key);
    });

    test('wsReceive pins the ws-received key regardless of operation', () {
      logger.wsReceive(source: 'ws', operation: 'anything');
      expect(logger.lastTrace!.key, ISpectLogType.wsReceived.key);
    });

    test('an error frame still resolves to the ws-error key', () {
      logger.wsReceive(
        source: 'ws',
        operation: 'receive',
        error: StateError('boom'),
      );
      expect(logger.lastTrace!.key, ISpectLogType.wsError.key);
    });
  });

  group('wsState', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('emits the ws-state key, not the ws-received success key', () {
      logger.wsState(source: 'ws', state: 'open', target: 'wss://x/y');

      final log = logger.lastTrace!;
      expect(log.key, ISpectLogType.wsState.key);
      expect(log.key, isNot(ISpectLogType.wsReceived.key));
      expect(log.additionalData?[TraceKeys.category], wsCategory.id);
      expect(log.additionalData?[TraceKeys.success], isTrue);
      expect(log.traceMeta, containsPair('state', 'open'));
    });

    test('carries correlationId so state shares the session group', () {
      logger.wsState(
        source: 'ws',
        state: 'connecting',
        correlationId: 'session-1',
      );

      expect(
        logger.lastTrace!.additionalData?[TraceKeys.correlationId],
        'session-1',
      );
    });
  });

  // ── ISpectLogDataX ───────────────────────────────────────────────
  group('ISpectLogDataX', () {
    test('trace field getters return correct values', () {
      final log = ISpectLogData(
        'test',
        additionalData: const {
          TraceKeys.category: 'network',
          TraceKeys.source: 'dio',
          TraceKeys.operation: 'GET',
          TraceKeys.target: '/api',
          TraceKeys.durationMs: 42,
          TraceKeys.success: true,
          TraceKeys.meta: <String, dynamic>{'statusCode': 200},
        },
      );

      expect(log.traceCategory, 'network');
      expect(log.traceSource, 'dio');
      expect(log.traceOperation, 'GET');
      expect(log.traceTarget, '/api');
      expect(log.traceDurationMs, 42);
      expect(log.traceSuccess, isTrue);
      expect(log.isNetwork, isTrue);
      expect(log.httpStatusCode, 200);
    });

    test('defensive getters return null on wrong types', () {
      final log = ISpectLogData(
        'test',
        additionalData: const {
          TraceKeys.meta: 'not a map',
          TraceKeys.durationMs: 'not int',
          TraceKeys.category: 123,
        },
      );

      expect(log.traceMeta, isNull);
      expect(log.traceDurationMs, isNull);
      expect(log.traceCategory, isNull);
    });

    test('paymentAmount handles int as double', () {
      final log = ISpectLogData(
        'test',
        additionalData: const {
          TraceKeys.meta: <String, dynamic>{'amount': 100},
        },
      );
      expect(log.paymentAmount, 100.0);
    });

    test('v4 logs without trace fields return null', () {
      final log = ISpectLogData('old log');
      expect(log.traceCategory, isNull);
      expect(log.isNetwork, isFalse);
      expect(log.httpStatusCode, isNull);
    });
  });

  // ── Filters ──────────────────────────────────────────────────────
  group('Filters', () {
    test('CategoryFilter matches correct category', () {
      final filter = const CategoryFilter({'network'});
      final match = ISpectLogData(
        'test',
        additionalData: const {TraceKeys.category: 'network'},
      );
      final noMatch = ISpectLogData(
        'test',
        additionalData: const {TraceKeys.category: 'db'},
      );
      final missing = ISpectLogData('test');

      expect(filter.apply(match), isTrue);
      expect(filter.apply(noMatch), isFalse);
      expect(filter.apply(missing), isFalse);
    });

    test('SourceFilter matches correct source', () {
      final filter = const SourceFilter({'dio'});
      final match = ISpectLogData(
        'test',
        additionalData: const {TraceKeys.source: 'dio'},
      );
      expect(filter.apply(match), isTrue);
    });

    test('CorrelationFilter matches correlationId', () {
      final filter = const CorrelationFilter('abc');
      final match = ISpectLogData(
        'test',
        additionalData: const {TraceKeys.correlationId: 'abc'},
      );
      final noMatch = ISpectLogData(
        'test',
        additionalData: const {TraceKeys.correlationId: 'xyz'},
      );
      expect(filter.apply(match), isTrue);
      expect(filter.apply(noMatch), isFalse);
    });

    test('TransactionFilter matches transactionId', () {
      final filter = const TransactionFilter('txn-1');
      final match = ISpectLogData(
        'test',
        additionalData: const {TraceKeys.transactionId: 'txn-1'},
      );
      expect(filter.apply(match), isTrue);
    });
  });

  // ── FakeISpectLogger queries ─────────────────────────────────────
  group('FakeISpectLogger', () {
    test('query methods work correctly', () {
      final logger = FakeISpectLogger();
      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        success: true,
      );
      logger.trace(
        category: dbCategory,
        source: 'drift',
        operation: 'insert',
        success: false,
        error: Exception('fail'),
      );

      expect(logger.byCategory('network'), hasLength(1));
      expect(logger.bySource('drift'), hasLength(1));
      expect(logger.errors(), hasLength(1));
      expect(logger.byOperation('GET'), hasLength(1));
    });

    test('maxTraces enforces FIFO limit', () {
      final logger = FakeISpectLogger(maxTraces: 5);
      for (var i = 0; i < 10; i++) {
        logger.trace(
          category: dbCategory,
          source: 'test',
          operation: 'op$i',
        );
      }
      expect(logger.traces, hasLength(5));
      // First 5 were dropped
      expect(
        logger.traces.first.additionalData?[TraceKeys.operation],
        'op5',
      );
    });

    test('reset clears all traces', () {
      final logger = FakeISpectLogger();
      logger.trace(
        category: dbCategory,
        source: 'test',
        operation: 'op',
      );
      expect(logger.traces, isNotEmpty);
      logger.reset();
      expect(logger.traces, isEmpty);
    });

    test('direct logData does not queue while disabled', () {
      final logger = FakeISpectLogger()
        ..configure(options: ISpectLoggerOptions(enabled: false))
        ..logData(ISpectLogData('must not be retained'));

      expect(logger.traces, isEmpty);
    });

    test('direct logData does not queue after disposal', () async {
      final logger = FakeISpectLogger();
      await logger.dispose();

      logger.logData(ISpectLogData('must not be retained'));

      expect(logger.traces, isEmpty);
    });
  });

  test('safeTrace emits a constant failure diagnostic without stack details',
      () {
    final logger = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );

    safeTrace(
      logger,
      () => throw StateError('tenantSecret=TRACE_BUILDER_SECRET'),
    );

    expect(logger.history, hasLength(1));
    expect(logger.history.single.message, 'Trace builder failed safely.');
    expect(logger.history.single.message, isNot(contains('trace_test.dart')));
  });

  // ── Domain extensions ────────────────────────────────────────────
  group('Domain extensions', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

    test('disabled helpers do not inspect caller metadata or format values',
        () async {
      logger.configure(options: ISpectLoggerOptions(enabled: false));
      final meta = _ThrowingTraceMeta();
      final value = _HostileTraceValue();
      final stack = _HostileTraceStack();
      var runCalls = 0;

      logger
        ..auth(source: 'auth', operation: 'event', meta: meta)
        ..navigationTrace(
          source: 'router',
          operation: 'push',
          routeName: '/next',
          arguments: value,
          meta: meta,
        )
        ..performanceJank(
          source: 'frame',
          buildDuration: Duration.zero,
          rasterDuration: Duration.zero,
          totalSpan: Duration.zero,
          targetFrameTime: Duration.zero,
          stackTrace: stack,
          meta: meta,
        )
        ..push(source: 'push', operation: 'receive', meta: meta)
        ..sse(source: 'sse', operation: 'receive', meta: meta)
        ..stateChange(
          source: 'state',
          operation: 'change',
          fromState: value,
          toState: value,
          meta: meta,
        )
        ..storage(source: 'storage', operation: 'read', meta: meta)
        ..wsSend(source: 'ws', operation: 'send', meta: meta)
        ..wsReceive(source: 'ws', operation: 'receive', meta: meta)
        ..wsState(source: 'ws', state: 'open', meta: meta);

      Future<int> run() async => ++runCalls;

      await logger.authTrace(
        source: 'auth',
        operation: 'refresh',
        meta: meta,
        run: run,
      );
      await logger.graphqlTrace(
        source: 'graphql',
        operation: 'query',
        meta: meta,
        run: run,
      );
      await logger.paymentTrace(
        source: 'payments',
        operation: 'purchase',
        meta: meta,
        run: run,
      );
      await logger.storageTrace(
        source: 'storage',
        operation: 'write',
        meta: meta,
        run: run,
      );

      expect(runCalls, 4);
      expect(meta.keyReads, 0);
      expect(value.toJsonCalls, 0);
      expect(value.toStringCalls, 0);
      expect(stack.calls, 0);
      expect(logger.traces, isEmpty);
    });

    test('disposed helpers do not inspect caller metadata', () async {
      final meta = _ThrowingTraceMeta();
      final value = _HostileTraceValue();
      var runCalls = 0;
      await logger.dispose();

      logger
        ..auth(source: 'auth', operation: 'event', meta: meta)
        ..navigationTrace(
          source: 'router',
          operation: 'push',
          routeName: '/next',
          arguments: value,
          meta: meta,
        )
        ..stateChange(
          source: 'state',
          operation: 'change',
          fromState: value,
          toState: value,
          meta: meta,
        );

      final result = await logger.authTrace(
        source: 'auth',
        operation: 'refresh',
        meta: meta,
        run: () async => ++runCalls,
      );

      expect(result, 1);
      expect(runCalls, 1);
      expect(meta.keyReads, 0);
      expect(value.toJsonCalls, 0);
      expect(value.toStringCalls, 0);
      expect(logger.traces, isEmpty);
    });

    test('enabled helpers snapshot hostile values behind the safe boundary',
        () {
      final meta = _ThrowingTraceMeta();
      final value = _HostileTraceValue();
      final stack = _HostileTraceStack();

      expect(
        () => logger.navigationTrace(
          source: 'router',
          operation: 'push',
          routeName: '/next',
          arguments: value,
          meta: meta,
        ),
        returnsNormally,
      );
      expect(
        () => logger.performanceJank(
          source: 'frame',
          buildDuration: Duration.zero,
          rasterDuration: Duration.zero,
          totalSpan: Duration.zero,
          targetFrameTime: Duration.zero,
          stackTrace: stack,
          meta: meta,
        ),
        returnsNormally,
      );

      expect(value.toJsonCalls, 0);
      expect(value.toStringCalls, 0);
      expect(stack.calls, 0);
      expect(logger.traces, hasLength(2));
    });

    test('push auto-correlation uses messageId', () {
      logger.push(
        source: 'fcm',
        operation: 'received',
        messageId: 'msg-1',
      );
      final log = logger.traces.first;
      expect(
        log.additionalData?[TraceKeys.correlationId],
        'msg-1',
      );
    });

    test('push explicit correlationId overrides messageId', () {
      logger.push(
        source: 'fcm',
        operation: 'received',
        messageId: 'msg-1',
        correlationId: 'custom',
      );
      expect(
        logger.traces.first.additionalData?[TraceKeys.correlationId],
        'custom',
      );
    });

    test('analyticsEvent logs correctly', () {
      logger.analyticsEvent(
        source: 'firebase',
        event: 'purchase',
        parameters: {'item': 'premium'},
      );
      final log = logger.traces.first;
      expect(log.additionalData?[TraceKeys.category], 'analytics');
      expect(log.additionalData?[TraceKeys.operation], 'purchase');
    });
  });

  // ── RedactionService ─────────────────────────────────────────────
  group('RedactionService', () {
    test('redactTarget masks URL credentials', () {
      final result = RedactionService.redactTarget(
        'https://user:pass@host/path',
        defaultSensitiveKeys,
      );
      expect(result, contains('://REDACTED@'));
      expect(result, isNot(contains('user:pass')));
    });

    test('redactTarget masks query params', () {
      final result = RedactionService.redactTarget(
        '/api?token=abc&name=test',
        const {'token'},
      );
      expect(Uri.decodeFull(result), contains('token=[REDACTED]'));
      expect(result, contains('name=test'));
    });

    test('redactTarget leaves non-URL unchanged', () {
      final result =
          RedactionService.redactTarget('users', defaultSensitiveKeys);
      expect(result, 'users');
    });

    test('redactTarget masks sensitive URL fragment params', () {
      final result = RedactionService.redactTarget(
        'https://app/callback#access_token=abc123&id_token=xyz789',
        defaultSensitiveKeys,
      );
      expect(
        Uri.decodeFull(result),
        contains('access_token=[REDACTED]'),
      );
      expect(result, isNot(contains('abc123')));
      expect(result, isNot(contains('xyz789')));
    });

    test('redactTarget scrubs credentials in encoded nested URLs', () {
      var nested =
          'https://alice:hunter2@inner.test/path?token=NESTED_TARGET_SECRET';
      for (var index = 0; index < 2; index++) {
        nested = Uri.encodeQueryComponent(nested);
      }

      final result = RedactionService.redactTarget(
        'https://outer.test/callback?redirect=$nested',
        defaultSensitiveKeys,
      );
      var decoded = result;
      for (var index = 0; index < 2; index++) {
        decoded = Uri.decodeFull(decoded);
      }

      expect(decoded, isNot(contains('alice:hunter2')));
      expect(decoded, isNot(contains('NESTED_TARGET_SECRET')));
      expect(decoded, contains(defaultPlaceholder));
    });

    test('redactTarget scrubs encoded relative callback URLs', () {
      final nested = Uri.encodeQueryComponent(
        '/callback?token=RELATIVE_TARGET_SECRET&safe=visible',
      );

      final result = RedactionService.redactTarget(
        'https://outer.test/start?redirect=$nested',
        defaultSensitiveKeys,
      );
      final decoded = Uri.decodeComponent(result);

      expect(decoded, isNot(contains('RELATIVE_TARGET_SECRET')));
      expect(decoded, contains('safe=visible'));
      expect(decoded, contains(Uri.encodeComponent(defaultPlaceholder)));
    });

    test('redactExportString masks Bearer tokens', () {
      final result = RedactionService.redactExportString(
        'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9',
        defaultSensitiveKeys,
      );
      expect(result, 'Authorization: [REDACTED]');
    });

    test('redactExportString with null keys returns unchanged', () {
      const input = 'some text with token=abc';
      expect(RedactionService.redactExportString(input, null), input);
    });

    test('redactExportString redacts every key in query params', () {
      final result = RedactionService.redactExportString(
        'https://api.test/x?token=abc&password=p1&keep=ok&secret=s1',
        const {'token', 'password', 'secret'},
      );
      expect(result, contains('token=[REDACTED]'));
      expect(result, contains('password=[REDACTED]'));
      expect(result, contains('secret=[REDACTED]'));
      expect(result, contains('keep=ok'));
    });

    test('redactExportString redacts every key in JSON form', () {
      final result = RedactionService.redactExportString(
        '{"token": "abc", "password": "p1", "keep": "ok"}',
        const {'token', 'password'},
      );
      expect(result, contains('"token": "[REDACTED]"'));
      expect(result, contains('"password": "[REDACTED]"'));
      expect(result, contains('"keep": "ok"'));
    });

    test('redactExportString redacts numeric JSON values for sensitive keys',
        () {
      final result = RedactionService.redactExportString(
        '{"ssn": 123456789, "age": 42}',
        const {'ssn'},
      );
      expect(result, isNot(contains('123456789')));
      expect(result, contains('42'));
    });

    test('redactExportString leaves keys outside the set untouched', () {
      const input = 'https://api.test/x?session=keepme';
      expect(
        RedactionService.redactExportString(input, const {'token'}),
        input,
      );
    });
  });

  // ── Serialization ────────────────────────────────────────────────
  group('Serialization', () {
    test('toText produces readable output', () {
      final log = ISpectLogData(
        'test message',
        key: 'info',
        additionalData: const {
          TraceKeys.category: 'general',
          TraceKeys.source: 'app',
        },
      );
      final text = log.toText();
      expect(text, contains('test message'));
      expect(text, contains('info'));
    });

    test('toMarkdown produces markdown', () {
      final log = ISpectLogData(
        'test',
        key: 'debug',
        logLevel: LogLevel.debug,
      );
      final md = log.toMarkdown();
      expect(md, contains('[DEBUG]'));
      expect(md, contains('`debug`'));
    });

    test('LogExporter.toCsv contains header', () {
      final log = ISpectLogData('test', key: 'info');
      final csv = LogExporter.toCsv([log]);
      expect(csv, startsWith('time,level,key,'));
    });

    test('LogExporter caps at maxLogs', () {
      final logs = List.generate(100, (i) => ISpectLogData('log $i'));
      final text = LogExporter.toText(logs, maxLogs: 10);
      expect(text, contains('capped from 100'));
    });
  });

  group('additionalData export redaction (M8)', () {
    ISpectLogData secretLog() => ISpectLogData(
          'user action',
          key: 'info',
          additionalData: const {
            TraceKeys.category: 'general',
            'password': 'hunter2',
            'userMeta': {'token': 'super-secret-token'},
          },
        );

    test('toText masks nested sensitive additionalData when redactKeys given',
        () {
      final text = secretLog().toText(redactKeys: {'password', 'token'});

      expect(text, isNot(contains('hunter2')));
      expect(text, isNot(contains('super-secret-token')));
      expect(text, contains('[REDACTED]'));
      expect(text, contains('general'));
    });

    test(
        'toMarkdown masks nested sensitive additionalData when redactKeys given',
        () {
      final md = secretLog().toMarkdown(redactKeys: {'password', 'token'});

      expect(md, isNot(contains('hunter2')));
      expect(md, isNot(contains('super-secret-token')));
      expect(md, contains('[REDACTED]'));
    });

    test(
        'toJsonLines masks nested sensitive additionalData when redactKeys given',
        () {
      final jsonl = LogExporter.toJsonLines(
        [secretLog()],
        redactKeys: {'password', 'token'},
      );

      expect(jsonl, isNot(contains('hunter2')));
      expect(jsonl, isNot(contains('super-secret-token')));
      expect(jsonl, contains('[REDACTED]'));
    });

    test('exports redact secrets embedded in free-form messages', () {
      final log = ISpectLogData(
        'failed https://alice:password@example.test/users?token=MESSAGE_SECRET&api_key=PATTERN_SECRET',
      );

      final text = LogExporter.toText(
        [log],
        redactKeys: defaultSensitiveKeys,
      );
      final markdown = LogExporter.toMarkdown(
        [log],
        redactKeys: defaultSensitiveKeys,
      );
      final jsonLines = LogExporter.toJsonLines(
        [log],
        redactKeys: defaultSensitiveKeys,
      );

      for (final exported in [text, markdown, jsonLines]) {
        expect(exported, isNot(contains('password')));
        expect(exported, isNot(contains('MESSAGE_SECRET')));
        expect(exported, isNot(contains('PATTERN_SECRET')));
        expect(exported, contains('[REDACTED]'));
      }
    });

    test('toJsonLines preserves logs with unsupported BLoC event objects', () {
      final jsonl = LogExporter.toJsonLines(
        [
          ISpectLogData(
            'authentication status check',
            id: 'AUTH-EVENT',
            additionalData: const {
              TraceKeys.meta: {
                'event': _CheckStatusAuthEvent(),
                'authorization': 'Bearer secret-token',
              },
            },
          ),
        ],
        redactKeys: const {'authorization'},
      );

      final decoded = jsonDecode(jsonl) as Map<String, dynamic>;
      final additionalData = decoded['additional-data'] as Map<String, dynamic>;
      final metadata = additionalData[TraceKeys.meta] as Map<String, dynamic>;

      expect(decoded['id'], 'AUTH-EVENT');
      expect(
        metadata['event'],
        contains('_CheckStatusAuthEvent'),
      );
      expect(metadata['authorization'], isNot(contains('secret-token')));
      expect(decoded, isNot(contains('export-error')));
    });

    test('toText uses default redaction when redactKeys is omitted', () {
      final text = secretLog().toText();

      expect(text, isNot(contains('hunter2')));
      expect(text, isNot(contains('super-secret-token')));
      expect(text, contains(defaultPlaceholder));
    });

    test('toJsonLines uses default redaction when redactKeys is omitted', () {
      final jsonl = LogExporter.toJsonLines([secretLog()]);

      expect(jsonl, isNot(contains('hunter2')));
      expect(jsonl, isNot(contains('super-secret-token')));
      expect(jsonl, contains(defaultPlaceholder));
    });
  });

  // ── isHttpLog includes httpError ─────────────────────────────────
  test('isHttpLog includes httpError', () {
    final log = ISpectLogData('err', key: 'http-error');
    expect(log.isHttpLog, isTrue);
  });

  // ── truncateValue ────────────────────────────────────────────────
  group('truncateValue', () {
    test('truncates long strings', () {
      final result = truncateValue('a' * 100, 10);
      expect(result, isA<String>());
      expect((result! as String).length, lessThan(100));
    });

    test('passes non-strings through', () {
      expect(truncateValue(42, 10), 42);
      expect(truncateValue(null, 10), isNull);
    });
  });
}
