import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/drift_interceptor.dart';
import 'package:test/test.dart';

/// No-op user — tables created via sqlite3 [setup] callback.
final class _NoOpUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor e, OpeningDetails d) async {}
}

void main() {
  late ISpectLogger logger;
  late QueryExecutor executor;

  setUp(() async {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();

    // Real NativeDatabase with interceptor plugged in natively.
    executor = NativeDatabase.memory(
      setup: (db) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS t (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            value TEXT
          )
        ''');
      },
    ).interceptWith(ISpectDriftInterceptor(logger: logger));

    await executor.ensureOpen(_NoOpUser());
  });

  tearDown(() async {
    await executor.close();
    ISpectDbCore.config = ISpectDbConfig();
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('runSelect', () {
    test('queries real data and logs', () async {
      await executor.runInsert('INSERT INTO t (value) VALUES (?)', ['A']);
      await executor.runInsert('INSERT INTO t (value) VALUES (?)', ['B']);

      final rows = await executor.runSelect('SELECT * FROM t', []);

      expect(rows.length, 2);
      expect(lastAdditional()['source'], 'drift');
      expect(lastAdditional()['operation'], 'select');
      expect(logger.history.last.key, 'db-query');
    });
  });

  group('runInsert', () {
    test('inserts and logs', () async {
      final id = await executor.runInsert(
        'INSERT INTO t (value) VALUES (?)',
        ['X'],
      );

      expect(id, isPositive);
      expect(lastAdditional()['operation'], 'insert');
    });
  });

  group('runUpdate', () {
    test('updates and logs', () async {
      await executor.runInsert('INSERT INTO t (value) VALUES (?)', ['old']);
      final affected = await executor.runUpdate(
        'UPDATE t SET value = ? WHERE value = ?',
        ['new', 'old'],
      );

      expect(affected, 1);
      expect(lastAdditional()['operation'], 'update');
    });
  });

  group('runDelete', () {
    test('deletes and logs', () async {
      await executor.runInsert('INSERT INTO t (value) VALUES (?)', ['del']);
      final affected = await executor.runDelete(
        'DELETE FROM t WHERE value = ?',
        ['del'],
      );

      expect(affected, 1);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('runCustom', () {
    test('executes and logs', () async {
      await executor.runCustom('PRAGMA journal_mode=WAL');

      expect(lastAdditional()['operation'], 'execute');
    });
  });

  group('runBatched', () {
    test('batches and logs', () async {
      await executor.runBatched(
        BatchedStatements(
          ['INSERT INTO t (value) VALUES (?)'],
          [
            ArgumentsForBatchedStatement(0, ['B1']),
            ArgumentsForBatchedStatement(0, ['B2']),
          ],
        ),
      );

      final rows = await executor.runSelect(
        'SELECT * FROM t WHERE value LIKE ?',
        ['B%'],
      );
      expect(rows.length, 2);
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final custom = NativeDatabase.memory().interceptWith(
        ISpectDriftInterceptor(logger: logger, source: 'my-drift'),
      );
      await custom.ensureOpen(_NoOpUser());
      await custom.runCustom('SELECT 1');
      await custom.close();

      final log = logger.history.lastWhere(
        (e) => e.additionalData?['operation'] == 'execute',
      );
      expect(log.additionalData?['source'], 'my-drift');
    });
  });
}
