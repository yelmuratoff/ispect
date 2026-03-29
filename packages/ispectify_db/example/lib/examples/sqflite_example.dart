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

Future<void> sqfliteExample() async {
  sqfliteFfiInit();

  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig(
    slowThreshold: const Duration(milliseconds: 100),
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
    );
  ''');

  await db.execute('''
    CREATE TABLE posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      user_id INTEGER,
      FOREIGN KEY (user_id) REFERENCES users (id)
    );
  ''');

  // Insert with raw SQL
  final id1 = await db.rawInsert(
    'INSERT INTO users (name, email) VALUES (?, ?)',
    ['Alice', 'alice@example.com'],
  );

  // Insert with convenience method
  await db.insert('users', {
    'name': 'Bob',
    'email': 'bob@example.com',
  });

  // Query
  await db.rawQuery('SELECT * FROM users WHERE name LIKE ?', ['%']);

  // Convenience query
  await db.query('users', where: 'name = ?', whereArgs: ['Alice']);

  // Update
  await db.update(
    'users',
    {'email': 'alice@new.com'},
    where: 'id = ?',
    whereArgs: [id1],
  );

  // Insert into second table
  await db.insert('posts', {
    'title': 'My first post',
    'user_id': id1,
  });

  // Transaction
  await db.transaction((txn) async {
    await txn.rawInsert(
      'INSERT INTO users (name, email) VALUES (?, ?)',
      ['Charlie', 'charlie@example.com'],
    );
    await txn.rawDelete('DELETE FROM users WHERE name = ?', ['Bob']);
  });

  // Final count
  await db.rawQuery('SELECT COUNT(*) as cnt FROM users');

  await db.close();
}
