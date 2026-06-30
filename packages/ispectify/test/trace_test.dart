// ignore_for_file: cascade_invocations, avoid_redundant_argument_values, prefer_const_declarations, prefer_int_literals

import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/trace/trace_helpers.dart';
import 'package:ispectify/src/trace/trace_message.dart';
import 'package:test/test.dart';

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

    test('logKey override works', () {
      logger.trace(
        category: networkCategory,
        source: 'dio',
        operation: 'GET',
        logKey: ISpectLogType.httpRequest.key,
      );
      expect(logger.traces.first.key, 'http-request');
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
      expect(logger.traces, hasLength(1));
    });

    test('sampling 0.0 executes run but skips log', () async {
      final result = await logger.traceAsync(
        category: dbCategory,
        source: 'test',
        operation: 'get',
        run: () async => 'ok',
        sample: 0,
      );
      expect(result, 'ok');
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
      );
      expect(token, isNotNull);

      logger.traceEnd(token, value: 'ok', success: true);
      expect(logger.traces, hasLength(1));
      final log = logger.traces.first;
      expect(log.additionalData?[TraceKeys.durationMs], isNotNull);
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
  });

  // ── wsState (ws-state key) ───────────────────────────────────────
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
  });

  // ── Domain extensions ────────────────────────────────────────────
  group('Domain extensions', () {
    late FakeISpectLogger logger;
    setUp(() => logger = FakeISpectLogger());

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
      expect(result, contains('token=[REDACTED]'));
      expect(result, contains('name=test'));
    });

    test('redactTarget leaves non-URL unchanged', () {
      final result =
          RedactionService.redactTarget('users', defaultSensitiveKeys);
      expect(result, 'users');
    });

    test('redactExportString masks Bearer tokens', () {
      final result = RedactionService.redactExportString(
        'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9',
        defaultSensitiveKeys,
      );
      expect(result, contains('Bearer [REDACTED]'));
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

    test('toText leaves additionalData raw when redactKeys is null (opt-out)',
        () {
      final text = secretLog().toText();

      expect(text, contains('hunter2'));
      expect(text, contains('super-secret-token'));
    });

    test('toJsonLines leaves additionalData raw when redactKeys null (opt-out)',
        () {
      final jsonl = LogExporter.toJsonLines([secretLog()]);

      expect(jsonl, contains('hunter2'));
      expect(jsonl, contains('super-secret-token'));
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
