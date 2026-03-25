import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/drift_interceptor.dart';
import 'package:test/test.dart';

/// No-op user that creates tables via sqlite3 [setup] callback.
final class _NoOpUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor e, OpeningDetails d) async {}
}

void main() {
  late ISpectLogger logger;
  late NativeDatabase rawDb;
  late ISpectDriftExecutor traced;

  setUp(() async {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();

    rawDb = NativeDatabase.memory(
      setup: (db) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS t (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            value TEXT
          )
        ''');
      },
    );

    traced = ISpectDriftExecutor(delegate: rawDb, logger: logger);
    // Mark the executor as opened.
    await traced.ensureOpen(_NoOpUser());
  });

  tearDown(() async {
    await rawDb.close();
    ISpectDbCore.config = ISpectDbConfig();
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('runSelect', () {
    test('queries real data and logs', () async {
      await traced.runInsert('INSERT INTO t (value) VALUES (?)', ['A']);
      await traced.runInsert('INSERT INTO t (value) VALUES (?)', ['B']);

      final rows = await traced.runSelect('SELECT * FROM t', []);

      expect(rows.length, 2);
      expect(lastAdditional()['source'], 'drift');
      expect(lastAdditional()['operation'], 'select');
      expect(logger.history.last.key, 'db-query');
    });
  });

  group('runInsert', () {
    test('inserts and logs', () async {
      final id = await traced.runInsert(
        'INSERT INTO t (value) VALUES (?)',
        ['X'],
      );

      expect(id, isPositive);
      expect(lastAdditional()['operation'], 'insert');
    });
  });

  group('runUpdate', () {
    test('updates and logs', () async {
      await traced.runInsert('INSERT INTO t (value) VALUES (?)', ['old']);
      final affected = await traced.runUpdate(
        'UPDATE t SET value = ? WHERE value = ?',
        ['new', 'old'],
      );

      expect(affected, 1);
      expect(lastAdditional()['operation'], 'update');
    });
  });

  group('runDelete', () {
    test('deletes and logs', () async {
      await traced.runInsert('INSERT INTO t (value) VALUES (?)', ['del']);
      final affected = await traced.runDelete(
        'DELETE FROM t WHERE value = ?',
        ['del'],
      );

      expect(affected, 1);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('runCustom', () {
    test('executes and logs', () async {
      await traced.runCustom('PRAGMA journal_mode=WAL');

      expect(lastAdditional()['operation'], 'execute');
    });
  });

  group('runBatched', () {
    test('batches and logs', () async {
      await traced.runBatched(
        BatchedStatements(
          ['INSERT INTO t (value) VALUES (?)'],
          [
            ArgumentsForBatchedStatement(0, ['B1']),
            ArgumentsForBatchedStatement(0, ['B2']),
          ],
        ),
      );

      final rows = await traced.runSelect(
        'SELECT * FROM t WHERE value LIKE ?',
        ['B%'],
      );
      expect(rows.length, 2);
    });
  });

  group('beginTransaction', () {
    test('returns a TransactionExecutor', () {
      final txn = traced.beginTransaction();
      expect(txn, isA<TransactionExecutor>());
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final customDb = NativeDatabase.memory();
      final custom = ISpectDriftExecutor(
        delegate: customDb,
        logger: logger,
        source: 'my-drift',
      );
      await custom.ensureOpen(_NoOpUser());
      await custom.runCustom('SELECT 1');
      await customDb.close();

      final log = logger.history.lastWhere(
        (e) => e.additionalData?['operation'] == 'execute',
      );
      expect(log.additionalData?['source'], 'my-drift');
    });
  });
}
