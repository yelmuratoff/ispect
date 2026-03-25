/// Example: drift interceptor setup.
///
/// Drift requires code generation for full usage. This example shows
/// how to plug the interceptor into a drift database.
///
/// ## With a real drift database
/// ```dart
/// @DriftDatabase(tables: [Users, Todos])
/// class AppDatabase extends _$AppDatabase {
///   AppDatabase(QueryExecutor executor) : super(executor);
///
///   @override
///   int get schemaVersion => 1;
/// }
///
/// // Wrap the native executor:
/// final executor = ISpectDriftExecutor(
///   delegate: NativeDatabase.memory(),
///   logger: ISpectLogger(),
/// );
/// final db = AppDatabase(executor);
/// ```
///
/// ## Running this example
/// ```bash
/// dart run lib/examples/drift_example.dart
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/drift_interceptor.dart';

/// Minimal QueryExecutorUser for standalone executor usage.
final class _StandaloneUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}

void main() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig(
    slowQueryThreshold: const Duration(milliseconds: 100),
  );

  final executor = ISpectDriftExecutor(
    delegate: NativeDatabase.memory(),
    logger: logger,
  );

  // Open (triggers table creation via beforeOpen)
  await executor.ensureOpen(_StandaloneUser());

  // Insert
  final id1 = await executor.runInsert(
    'INSERT INTO todos (title) VALUES (?)',
    ['Buy groceries'],
  );
  logger.info('Inserted todo id: $id1');

  await executor.runInsert(
    'INSERT INTO todos (title) VALUES (?)',
    ['Write tests'],
  );

  // Select
  final todos = await executor.runSelect(
    'SELECT * FROM todos WHERE done = ?',
    [0],
  );
  logger.info('Found ${todos.length} pending todos');

  // Update
  final affected = await executor.runUpdate(
    'UPDATE todos SET done = 1 WHERE id = ?',
    [id1],
  );
  logger.info('Completed $affected todos');

  // Delete
  final deleted = await executor.runDelete(
    'DELETE FROM todos WHERE done = 1',
    [],
  );
  logger.info('Deleted $deleted completed todos');

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
  logger.info('Batch inserted 3 todos');

  // Custom
  await executor.runCustom('PRAGMA journal_mode=WAL');

  await executor.close();
}
