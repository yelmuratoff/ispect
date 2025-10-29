import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;

  setUp(() {
    logger = ISpectLogger();
    ISpectDbCore.config = const ISpectDbConfig(
      sampleRate: null,
      redact: true,
      redactKeys: ['password', 'token'],
      maxValueLength: 50,
      maxArgsLength: 12,
      maxStatementLength: 40,
      attachStackOnError: true,
      enableTransactionMarkers: true,
      slowQueryThreshold: Duration(milliseconds: 1),
    );
  });

  test('db logs fields and digest/truncation', () async {
    logger.db(
      source: 'sqflite',
      operation: 'query',
      statement: 'SELECT * FROM users WHERE name = \"VeryVeryLongName\"',
      table: 'users',
      args: ['aaaaaaaaaaaa-too-long'],
      namedArgs: {'password': 'secret', 'q': 'short'},
      success: true,
      duration: const Duration(milliseconds: 10),
      meta: {'note': 'test'},
    );

    expect(logger.history, isNotEmpty);
    final e = logger.history.last;
    expect(e.key, anyOf('db-query', 'db-result'));
    final add = e.additionalData!;
    expect(add['statement'], isA<String>());
    expect(add['statementDigest'], isA<String>());
    expect((add['args'] as List).first.toString().contains('…'), isTrue);
    expect((add['namedArgs'] as Map)['password'], '***');
    expect(add['durationMs'], greaterThanOrEqualTo(10));
    expect(add['slow'], isTrue); // slow threshold is 1ms
  });

  test('dbTrace captures error and stack trace', () async {
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
      // ignore
    }

    final e = logger.history.last;
    expect(e.key, 'db-error');
    expect(e.stackTrace, isNotNull);
    final add = e.additionalData!;
    expect(add['success'], isFalse);
    expect(add['key'], 'a');
  });

  test('dbTrace projects result and sets items count', () async {
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
    final e = logger.history.last;
    final add = e.additionalData!;
    expect(add['items'], 2);
    expect((add['value'] as String).contains('rows: 2'), isTrue);
  });

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

    final txLogs = logger.history.where((e) =>
        (e.additionalData?['operation'] as String?)
            ?.startsWith('transaction-') ==
        true);
    expect(txLogs.length, greaterThanOrEqualTo(2));
    final ids = txLogs
        .map((e) => e.additionalData?['transactionId'])
        .whereType<String>()
        .toSet();
    expect(ids.length, 1); // same id across markers
  });

  test('dbTransaction does not commit after rollback', () async {
    await expectLater(
      () => logger.dbTransaction(
        source: 'sqflite',
        logMarkers: true,
        run: () async => throw StateError('fail'),
      ),
      throwsA(isA<StateError>()),
    );

    final txLogs = logger.history.where((e) =>
        (e.additionalData?['operation'] as String?)
            ?.startsWith('transaction-') ==
        true);
    final ops = txLogs.map((e) => e.additionalData?['operation']).toList();
    expect(ops, contains('transaction-begin'));
    expect(ops, contains('transaction-rollback'));
    expect(ops, isNot(contains('transaction-commit')));
  });

  test('db() sets error logs to LogLevel.error', () async {
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
}
