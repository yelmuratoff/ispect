import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;

  setUp(() {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig(
      redactKeys: const ['password', 'token'],
      maxValueLength: 50,
      maxArgsLength: 12,
      maxStatementLength: 40,
      attachStackOnError: true,
      enableTransactionMarkers: true,
      slowQueryThreshold: const Duration(milliseconds: 1),
    );
  });

  tearDown(() {
    ISpectDbCore.config = ISpectDbConfig();
  });

  group('db()', () {
    test('logs fields and digest/truncation', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM users WHERE name = "VeryVeryLongName"',
        table: 'users',
        args: ['aaaaaaaaaaaa-too-long'],
        namedArgs: {'password': 'secret', 'q': 'short'},
        success: true,
        duration: const Duration(milliseconds: 10),
        meta: {'note': 'test'},
      );

      expect(logger.history, isNotEmpty);
      final entry = logger.history.last;
      expect(entry.key, anyOf('db-query', 'db-result'));
      final add = entry.additionalData ?? {};
      expect(add['statement'], isA<String>());
      expect(add['statementDigest'], isA<String>());
      expect(
        (add['args'] as List).first.toString().contains('...'),
        isTrue,
      );
      expect((add['namedArgs'] as Map)['password'], '***');
      expect(add['durationMs'], greaterThanOrEqualTo(10));
      expect(add['slow'], isTrue);
    });

    test('sets error logs to LogLevel.error', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT 1',
        success: false,
        error: 'boom',
      );
      final last = logger.history.last;
      expect(last.key, 'db-error');
      expect(last.logLevel, LogLevel.error);
    });

    test('handles null statement and empty args', () {
      logger.db(
        source: 'kv',
        operation: 'get',
        key: 'myKey',
        args: [],
        namedArgs: {},
      );

      expect(logger.history, isNotEmpty);
      final add = logger.history.last.additionalData ?? {};
      expect(add.containsKey('statement'), isFalse);
      expect(add.containsKey('statementDigest'), isFalse);
      expect(add['key'], 'myKey');
    });

    test('skips redaction when redact is false', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM users',
        namedArgs: {'password': 'secret123'},
        redact: false,
      );

      final add = logger.history.last.additionalData ?? {};
      expect((add['namedArgs'] as Map)['password'], 'secret123');
    });

    test('preserves positional args when statement has no sensitive columns', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM orders WHERE total > ?',
        args: [100, 'visible'],
      );

      final add = logger.history.last.additionalData ?? {};
      final args = add['args'] as List;
      expect(args, containsAll([100, 'visible']));
    });

    test('redacts positional args when statement mentions sensitive column', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT * FROM users WHERE password = ?',
        args: ['super-secret'],
      );

      final add = logger.history.last.additionalData ?? {};
      final args = add['args'] as List;
      expect(args.first, '***');
    });

    test('logs value and projection correctly', () {
      logger.db(
        source: 'kv',
        operation: 'read',
        key: 'k',
        value: 'raw-value',
        projection: 'projected-value',
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['value'], contains('projected-value'));
    });

    test('pickLogKey returns db-query for read operations', () {
      for (final op in ['query', 'select', 'read', 'get']) {
        logger.db(source: 'test', operation: op, success: true);
        expect(logger.history.last.key, 'db-query');
      }
    });

    test('pickLogKey returns db-result for write operations', () {
      for (final op in ['insert', 'update', 'delete']) {
        logger.db(source: 'test', operation: op, success: true);
        expect(logger.history.last.key, 'db-result');
      }
    });

    test('logs sizeBytes for file operations', () {
      logger.db(
        source: 'file',
        operation: 'write',
        target: '/data/cache/image.png',
        sizeBytes: 2048,
        success: true,
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['sizeBytes'], 2048);
    });

    test('logs cacheHit for cache operations', () {
      logger.db(
        source: 'cache',
        operation: 'get',
        key: 'user:123',
        cacheHit: true,
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['cacheHit'], isTrue);
    });

    test('logs cache miss', () {
      logger.db(
        source: 'cache',
        operation: 'get',
        key: 'user:999',
        cacheHit: false,
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['cacheHit'], isFalse);
    });

    test('omits sizeBytes and cacheHit when null', () {
      logger.db(source: 'kv', operation: 'get', key: 'k');

      final add = logger.history.last.additionalData ?? {};
      expect(add.containsKey('sizeBytes'), isFalse);
      expect(add.containsKey('cacheHit'), isFalse);
    });

    test('does not mark as slow when duration is under threshold', () {
      logger.db(
        source: 'sqflite',
        operation: 'query',
        duration: Duration.zero,
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add.containsKey('slow'), isFalse);
    });
  });

  group('sqlDigest', () {
    test('returns null for null or empty input', () {
      expect(ISpectDbCore.sqlDigest(null), isNull);
      expect(ISpectDbCore.sqlDigest(''), isNull);
    });

    test('normalizes single-quoted strings to ?', () {
      final digest = ISpectDbCore.sqlDigest("SELECT * FROM t WHERE a = 'foo'");
      expect(digest, isNotNull);
      expect(digest, contains('?'));
      expect(digest, isNot(contains('foo')));
    });

    test('normalizes double-quoted strings to ?', () {
      final digest =
          ISpectDbCore.sqlDigest('SELECT * FROM t WHERE a = "bar"');
      expect(digest, isNotNull);
      expect(digest, contains('?'));
      expect(digest, isNot(contains('bar')));
    });

    test('normalizes digits to ?', () {
      final digest = ISpectDbCore.sqlDigest('SELECT * FROM t WHERE id = 42');
      expect(digest, isNotNull);
      expect(digest, contains('?'));
      expect(digest, isNot(contains('42')));
    });

    test('produces stable hash for identical normalized statements', () {
      final digest1 = ISpectDbCore.sqlDigest("SELECT * FROM t WHERE a = 'x'");
      final digest2 = ISpectDbCore.sqlDigest("SELECT * FROM t WHERE a = 'y'");
      expect(digest1, equals(digest2));
    });

    test('produces different hash for structurally different statements', () {
      final digest1 = ISpectDbCore.sqlDigest('SELECT * FROM users');
      final digest2 = ISpectDbCore.sqlDigest('DELETE FROM users');
      expect(digest1, isNot(equals(digest2)));
    });

    test('truncates long statements to 80 chars before hash', () {
      final longStmt = 'SELECT ${'a, ' * 100}FROM t';
      final digest = ISpectDbCore.sqlDigest(longStmt)!;
      final prefix = digest.split('|').first;
      expect(prefix.length, 80);
    });
  });

  group('sampleRate', () {
    test('sampleRate 0.0 drops all logs', () {
      ISpectDbCore.config = ISpectDbConfig(sampleRate: 0);
      logger.db(source: 'test', operation: 'query');
      expect(logger.history, isEmpty);
    });

    test('sampleRate 1.0 logs everything', () {
      ISpectDbCore.config = ISpectDbConfig(sampleRate: 1);
      for (var i = 0; i < 10; i++) {
        logger.db(source: 'test', operation: 'query');
      }
      expect(logger.history.length, 10);
    });

    test('sampleRate null logs everything', () {
      ISpectDbCore.config = ISpectDbConfig();
      for (var i = 0; i < 5; i++) {
        logger.db(source: 'test', operation: 'query');
      }
      expect(logger.history.length, 5);
    });

    test('per-call sample override takes precedence', () {
      ISpectDbCore.config = ISpectDbConfig(sampleRate: 1);
      logger.db(source: 'test', operation: 'query', sample: 0);
      expect(logger.history, isEmpty);
    });

    test('dbTrace with sampleRate 0 still executes the callback', () async {
      ISpectDbCore.config = ISpectDbConfig(sampleRate: 0);
      var executed = false;
      await logger.dbTrace(
        source: 'test',
        operation: 'query',
        run: () async {
          executed = true;
        },
      );
      expect(executed, isTrue);
      expect(logger.history, isEmpty);
    });
  });

  group('dbTrace', () {
    test('captures error and stack trace', () async {
      Future<void> failing() async => Future<void>.error(StateError('x'));
      try {
        await logger.dbTrace<void>(
          source: 'kv',
          operation: 'write',
          key: 'a',
          run: () async => failing(),
        );
        fail('should throw');
      } catch (_) {
        // expected
      }

      final entry = logger.history.last;
      expect(entry.key, 'db-error');
      expect(entry.stackTrace, isNotNull);
      final add = entry.additionalData ?? {};
      expect(add['success'], isFalse);
      expect(add['key'], 'a');
    });

    test('projects result and sets items count', () async {
      final res = await logger.dbTrace<List<Map<String, Object?>>>(
        source: 'sqflite',
        operation: 'query',
        table: 't',
        run: () async => [
          {'id': 1},
          {'id': 2},
        ],
        projectResult: (rows) => {'rows': rows.length},
      );
      expect(res.length, 2);
      final entry = logger.history.last;
      final add = entry.additionalData ?? {};
      expect(add['items'], 2);
      expect((add['value'] as String).contains('rows: 2'), isTrue);
    });

    test('records duration', () async {
      await logger.dbTrace(
        source: 'test',
        operation: 'query',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        },
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['durationMs'], isA<int>());
      expect(add['durationMs'] as int, greaterThanOrEqualTo(1));
    });

    test('passes sizeBytes and cacheHit through', () async {
      await logger.dbTrace(
        source: 'cache',
        operation: 'get',
        key: 'user:1',
        sizeBytes: 512,
        cacheHit: true,
        run: () async => 'cached-value',
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['sizeBytes'], 512);
      expect(add['cacheHit'], isTrue);
    });
  });

  group('dbStart / dbEnd', () {
    test('logs with measured duration', () async {
      final token = logger.dbStart(
        source: 'sqflite',
        operation: 'query',
        statement: 'SELECT 1',
        table: 'users',
      );

      await Future<void>.delayed(const Duration(milliseconds: 5));

      logger.dbEnd(
        token,
        value: 'result',
        success: true,
        items: 1,
      );

      expect(logger.history, isNotEmpty);
      final add = logger.history.last.additionalData ?? {};
      expect(add['source'], 'sqflite');
      expect(add['operation'], 'query');
      expect(add['table'], 'users');
      expect(add['items'], 1);
      expect(add['durationMs'], isA<int>());
      expect(add['durationMs'] as int, greaterThanOrEqualTo(1));
    });

    test('defaults source and operation to custom', () {
      final token = logger.dbStart();
      logger.dbEnd(token);

      final add = logger.history.last.additionalData ?? {};
      expect(add['source'], 'custom');
      expect(add['operation'], 'custom');
    });

    test('merges token meta with dbEnd meta', () {
      final token = logger.dbStart(
        source: 'kv',
        operation: 'write',
        meta: {'a': '1'},
      );
      logger.dbEnd(token, meta: {'b': '2'});

      final add = logger.history.last.additionalData ?? {};
      final meta = add['meta'];
      expect(meta, isA<Map<String, Object?>>());
      expect((meta as Map<String, Object?>)['a'], '1');
      expect(meta['b'], '2');
    });

    test('infers error from error parameter', () {
      final token = logger.dbStart(source: 'db', operation: 'write');
      logger.dbEnd(token, error: 'connection lost');

      final entry = logger.history.last;
      expect(entry.key, 'db-error');
      final add = entry.additionalData ?? {};
      expect(add['success'], isFalse);
      expect(add['error'], 'connection lost');
    });

    test('uses monotonic Stopwatch for duration', () async {
      final token = logger.dbStart(source: 'db', operation: 'read');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      logger.dbEnd(token, success: true);

      final add = logger.history.last.additionalData ?? {};
      final durationMs = add['durationMs'] as int;
      expect(durationMs, greaterThanOrEqualTo(5));
    });

    test('passes sizeBytes and cacheHit through dbEnd', () {
      final token = logger.dbStart(source: 'file', operation: 'read');
      logger.dbEnd(
        token,
        success: true,
        sizeBytes: 4096,
        cacheHit: false,
      );

      final add = logger.history.last.additionalData ?? {};
      expect(add['sizeBytes'], 4096);
      expect(add['cacheHit'], isFalse);
    });
  });

  group('dbTransaction', () {
    test('transaction markers with shared transactionId', () async {
      await logger.dbTransaction(
        source: 'sqflite',
        logMarkers: true,
        run: () async {
          await logger.dbTrace(
            source: 'sqflite',
            operation: 'update',
            statement: 'UPDATE t SET a=?',
            args: [1],
            run: () async => 1,
          );
        },
      );

      final txLogs = logger.history.where(
        (e) =>
            (e.additionalData?['operation'] as String?)
                ?.startsWith('transaction-') ??
            false,
      );
      expect(txLogs.length, greaterThanOrEqualTo(2));
      final ids = txLogs
          .map((e) => e.additionalData?['transactionId'])
          .whereType<String>()
          .toSet();
      expect(ids.length, 1);
    });

    test('does not commit after rollback', () async {
      await expectLater(
        () => logger.dbTransaction(
          source: 'sqflite',
          logMarkers: true,
          run: () async => throw StateError('fail'),
        ),
        throwsA(isA<StateError>()),
      );

      final txLogs = logger.history.where(
        (e) =>
            (e.additionalData?['operation'] as String?)
                ?.startsWith('transaction-') ??
            false,
      );
      final ops =
          txLogs.map((e) => e.additionalData?['operation']).toList();
      expect(ops, contains('transaction-begin'));
      expect(ops, contains('transaction-rollback'));
      expect(ops, isNot(contains('transaction-commit')));
    });

    test('propagates transactionId to nested db calls via Zone', () async {
      String? capturedTxnId;
      await logger.dbTransaction(
        source: 'sqflite',
        logMarkers: true,
        run: () async {
          capturedTxnId = ISpectDbTxn.currentTransactionId();
          logger.db(source: 'sqflite', operation: 'insert');
        },
      );

      expect(capturedTxnId, isNotNull);
      expect(capturedTxnId!.length, 16);

      final insertLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'insert',
      );
      expect(
        insertLog.additionalData?['transactionId'],
        equals(capturedTxnId),
      );
    });
  });

  group('ISpectDbConfig', () {
    test('redactKeys is unmodifiable', () {
      final config = ISpectDbConfig(redactKeys: ['a', 'b']);
      expect(
        () => config.redactKeys.add('c'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('assert rejects sampleRate outside 0..1', () {
      expect(
        () => ISpectDbConfig(sampleRate: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ISpectDbConfig(sampleRate: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith preserves unchanged fields', () {
      final original = ISpectDbConfig(
        sampleRate: 0.5,
        redact: false,
        maxValueLength: 100,
        attachStackOnError: true,
      );
      final copied = original.copyWith(maxValueLength: 200);
      expect(copied.sampleRate, 0.5);
      expect(copied.redact, isFalse);
      expect(copied.maxValueLength, 200);
      expect(copied.attachStackOnError, isTrue);
    });
  });

  group('ISpectDbTxn', () {
    test('returns null outside of transaction zone', () {
      expect(ISpectDbTxn.currentTransactionId(), isNull);
    });

    test('returns txnId inside transaction zone', () async {
      String? captured;
      await ISpectDbTxn.runInTransactionZone('txn-123', () async {
        captured = ISpectDbTxn.currentTransactionId();
      });
      expect(captured, 'txn-123');
    });
  });

  group('genId', () {
    test('produces 16-char hex string', () {
      final id = ISpectDbCore.genId();
      expect(id.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(id), isTrue);
    });

    test('produces unique values', () {
      final ids = List.generate(100, (_) => ISpectDbCore.genId()).toSet();
      expect(ids.length, 100);
    });
  });

  group('buildMessage', () {
    test('includes all fields', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'sqflite',
        operation: 'query',
        table: 'users',
        target: 'primary',
        key: 'id',
        items: 5,
        affected: 3,
        sizeBytes: 2048,
        cacheHit: true,
        duration: const Duration(milliseconds: 42),
        success: true,
        value: 'data',
      );
      expect(msg, contains('[sqflite] query'));
      expect(msg, contains('users → primary'));
      expect(msg, contains('Key: id'));
      expect(msg, contains('Items: 5'));
      expect(msg, contains('Affected: 3'));
      expect(msg, contains('Size: 2.0 KB'));
      expect(msg, contains('Cache: HIT'));
      expect(msg, contains('Duration: 42ms'));
      expect(msg, contains('Success: true'));
      expect(msg, contains('Value: data'));
    });

    test('formats cache miss', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'cache',
        operation: 'get',
        cacheHit: false,
      );
      expect(msg, contains('Cache: MISS'));
    });

    test('formats bytes correctly', () {
      final small = ISpectDbCore.buildMessage(
        source: 'file',
        operation: 'write',
        sizeBytes: 500,
      );
      expect(small, contains('Size: 500 B'));

      final kb = ISpectDbCore.buildMessage(
        source: 'file',
        operation: 'write',
        sizeBytes: 1536,
      );
      expect(kb, contains('Size: 1.5 KB'));

      final mb = ISpectDbCore.buildMessage(
        source: 'file',
        operation: 'write',
        sizeBytes: 2 * 1024 * 1024,
      );
      expect(mb, contains('Size: 2.0 MB'));
    });

    test('formats zero bytes', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'file',
        operation: 'write',
        sizeBytes: 0,
      );
      expect(msg, contains('Size: 0 B'));
    });

    test('shows table only when target is null', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'sqflite',
        operation: 'query',
        table: 'users',
      );
      expect(msg, contains('[sqflite] query users'));
      expect(msg, isNot(contains('→')));
    });

    test('shows target only when table is null', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'file',
        operation: 'read',
        target: '/data/config.json',
      );
      expect(msg, contains('[file] read /data/config.json'));
      expect(msg, isNot(contains('→')));
    });

    test('shows table → target when both present', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'sqflite',
        operation: 'query',
        table: 'users',
        target: 'idx_email',
      );
      expect(msg, contains('users → idx_email'));
    });

    test('minimal message with only required fields', () {
      final msg = ISpectDbCore.buildMessage(
        source: 'kv',
        operation: 'get',
      );
      expect(msg, equals('[kv] get'));
    });
  });

  group('redactPositionalArgs (direct)', () {
    test('returns args unchanged when statement has no sensitive columns', () {
      final args = ISpectDbCore.redactPositionalArgs(
        [1, 'visible', true],
        ['password', 'token'],
        'SELECT * FROM orders WHERE total > ?',
      );
      expect(args, [1, 'visible', true]);
    });

    test('redacts all args when statement mentions a sensitive column', () {
      final args = ISpectDbCore.redactPositionalArgs(
        ['secret', 42],
        ['password', 'token'],
        'INSERT INTO users (name, password) VALUES (?, ?)',
      );
      expect(args, ['***', '***']);
    });

    test('redacts all args when statement is null (precaution)', () {
      final args = ISpectDbCore.redactPositionalArgs(
        ['a', 'b'],
        ['password'],
        null,
      );
      expect(args, ['***', '***']);
    });

    test('returns empty list as-is', () {
      final args = ISpectDbCore.redactPositionalArgs(
        [],
        ['password'],
        'SELECT 1',
      );
      expect(args, isEmpty);
    });

    test('preserves null elements in redacted list', () {
      final args = ISpectDbCore.redactPositionalArgs(
        [null, 'secret'],
        ['password'],
        null,
      );
      expect(args, [null, '***']);
    });
  });

  group('truncateValue', () {
    test('returns null for null input', () {
      expect(ISpectDbCore.truncateValue(null, 10), isNull);
    });

    test('truncates long strings', () {
      final result = ISpectDbCore.truncateValue('a' * 100, 10);
      expect(result, isA<String>());
      expect((result! as String).length, lessThanOrEqualTo(15));
    });

    test('returns non-string values unchanged', () {
      expect(ISpectDbCore.truncateValue(42, 5), 42);
      expect(ISpectDbCore.truncateValue(true, 5), true);
      expect(
        ISpectDbCore.truncateValue(['a', 'b'], 5),
        ['a', 'b'],
      );
    });
  });

  group('clean', () {
    test('removes null and empty-string values', () {
      final result = ISpectDbCore.clean({
        'keep': 'value',
        'removeNull': null,
        'removeEmpty': '',
        'keepZero': 0,
        'keepFalse': false,
      });
      expect(result, containsPair('keep', 'value'));
      expect(result, containsPair('keepZero', 0));
      expect(result, containsPair('keepFalse', false));
      expect(result.containsKey('removeNull'), isFalse);
      expect(result.containsKey('removeEmpty'), isFalse);
    });
  });
}
