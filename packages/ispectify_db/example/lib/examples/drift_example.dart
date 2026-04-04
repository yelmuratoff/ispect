/// Example: drift interceptor using native [QueryInterceptor].
///
/// ```bash
/// dart run lib/examples/drift_example.dart
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/drift_interceptor.dart';

/// Minimal QueryExecutorUser for standalone usage.
final class _StandaloneUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<void> driftExample() async {
  final logger = ISpectLogger();
  const dbConfig = ISpectDbConfig(
    slowThreshold: Duration(milliseconds: 100),
  );

  // Plug the interceptor into any drift executor — one line.
  final executor = NativeDatabase.memory(
    setup: (db) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          done INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        );
      ''');
    },
  ).interceptWith(ISpectDriftInterceptor(logger: logger, config: dbConfig));

  await executor.ensureOpen(_StandaloneUser());

  // Insert
  final id1 = await executor.runInsert(
    'INSERT INTO todos (title) VALUES (?)',
    ['Buy groceries'],
  );

  await executor.runInsert(
    'INSERT INTO todos (title) VALUES (?)',
    ['Write tests'],
  );

  // Insert into second table
  await executor.runInsert(
    'INSERT INTO categories (name) VALUES (?)',
    ['Work'],
  );

  // Select
  await executor.runSelect(
    'SELECT * FROM todos WHERE done = ?',
    [0],
  );

  // Update
  await executor.runUpdate(
    'UPDATE todos SET done = 1 WHERE id = ?',
    [id1],
  );

  // Delete
  await executor.runDelete(
    'DELETE FROM todos WHERE done = 1',
    [],
  );

  // Batch
  await executor.runBatched(
    BatchedStatements(
      ['INSERT INTO todos (title) VALUES (?)'],
      [
        ArgumentsForBatchedStatement(0, ['Task A']),
        ArgumentsForBatchedStatement(0, ['Task B']),
        ArgumentsForBatchedStatement(0, ['Task C']),
      ],
    ),
  );

  // Custom
  await executor.runCustom('PRAGMA journal_mode=WAL');

  await executor.close();
}
