/// Example: sqflite interceptor with a real in-memory SQLite database.
///
/// ```bash
/// dart run lib/examples/sqflite_example.dart
/// ```
library;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/sqflite_interceptor.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();

  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig(
    slowQueryThreshold: const Duration(milliseconds: 100),
    enableTransactionMarkers: true,
  );

  final realDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  final db = ISpectSqfliteDatabase(delegate: realDb, logger: logger);

  // Create table
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT
    )
  ''');

  // Insert with raw SQL
  final id1 = await db.rawInsert(
    'INSERT INTO users (name, email) VALUES (?, ?)',
    ['Alice', 'alice@example.com'],
  );
  logger.info('Inserted Alice with id: $id1');

  // Insert with convenience method
  final id2 = await db.insert('users', {
    'name': 'Bob',
    'email': 'bob@example.com',
  });
  logger.info('Inserted Bob with id: $id2');

  // Query
  final users = await db.rawQuery('SELECT * FROM users WHERE name LIKE ?', ['%']);
  logger.info('Found ${users.length} users');

  // Convenience query
  final aliceRows = await db.query('users', where: 'name = ?', whereArgs: ['Alice']);
  logger.info('Alice: ${aliceRows.first}');

  // Update
  final affected = await db.update(
    'users',
    {'email': 'alice@new.com'},
    where: 'id = ?',
    whereArgs: [id1],
  );
  logger.info('Updated $affected rows');

  // Transaction
  await db.transaction((txn) async {
    await txn.rawInsert(
      'INSERT INTO users (name, email) VALUES (?, ?)',
      ['Charlie', 'charlie@example.com'],
    );
    await txn.rawDelete('DELETE FROM users WHERE name = ?', ['Bob']);
  });

  // Final count
  final count = await db.rawQuery('SELECT COUNT(*) as cnt FROM users');
  logger.info('Final user count: ${count.first['cnt']}');

  await db.close();
}
