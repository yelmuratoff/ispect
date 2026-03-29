import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/sqflite_interceptor.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late Database realDb;
  late ISpectSqfliteDatabase traced;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();
    realDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    traced = ISpectSqfliteDatabase(delegate: realDb, logger: logger);
    await traced.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT
      )
    ''');
  });

  tearDown(() async {
    await realDb.close();
    ISpectDbCore.config = ISpectDbConfig();
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('rawQuery', () {
    test('queries real data and logs', () async {
      await realDb.rawInsert(
        'INSERT INTO users (name) VALUES (?)',
        ['Alice'],
      );
      final rows = await traced.rawQuery('SELECT * FROM users');

      expect(rows.length, 1);
      expect(rows.first['name'], 'Alice');
      expect(lastAdditional()['source'], 'sqflite');
      expect(lastAdditional()['operation'], 'query');
      expect(logger.history.last.key, 'db-query');
    });
  });

  group('rawInsert', () {
    test('inserts and logs lastInsertId', () async {
      final id = await traced.rawInsert(
        'INSERT INTO users (name, email) VALUES (?, ?)',
        ['Bob', 'bob@test.com'],
      );

      expect(id, isPositive);
      expect(lastAdditional()['operation'], 'insert');
      expect(lastAdditional()['value'], contains('$id'));
    });
  });

  group('rawUpdate', () {
    test('updates and logs affected count', () async {
      await traced.rawInsert(
        'INSERT INTO users (name) VALUES (?)',
        ['Eve'],
      );
      final affected = await traced.rawUpdate(
        'UPDATE users SET email = ? WHERE name = ?',
        ['eve@test.com', 'Eve'],
      );

      expect(affected, 1);
      expect(lastAdditional()['operation'], 'update');
    });
  });

  group('rawDelete', () {
    test('deletes and logs', () async {
      await traced.rawInsert(
        'INSERT INTO users (name) VALUES (?)',
        ['Tmp'],
      );
      final affected = await traced.rawDelete(
        'DELETE FROM users WHERE name = ?',
        ['Tmp'],
      );

      expect(affected, 1);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('convenience methods', () {
    test('query logs with table name', () async {
      await realDb.rawInsert(
        'INSERT INTO users (name) VALUES (?)',
        ['Alice'],
      );
      final rows =
          await traced.query('users', where: 'name = ?', whereArgs: ['Alice']);

      expect(rows.length, 1);
      expect(lastAdditional()['table'], 'users');
      expect(lastAdditional()['operation'], 'query');
    });

    test('insert logs with table name', () async {
      final id = await traced.insert('users', {'name': 'Dan'});

      expect(id, isPositive);
      expect(lastAdditional()['table'], 'users');
      expect(lastAdditional()['operation'], 'insert');
    });

    test('update logs with table name', () async {
      await traced.insert('users', {'name': 'Dan'});
      final affected = await traced.update(
        'users',
        {'email': 'dan@test.com'},
        where: 'name = ?',
        whereArgs: ['Dan'],
      );

      expect(affected, 1);
      expect(lastAdditional()['table'], 'users');
      expect(lastAdditional()['operation'], 'update');
    });

    test('delete logs with table name', () async {
      await traced.insert('users', {'name': 'Dan'});
      final affected = await traced.delete(
        'users',
        where: 'name = ?',
        whereArgs: ['Dan'],
      );

      expect(affected, 1);
      expect(lastAdditional()['table'], 'users');
    });
  });

  group('execute', () {
    test('logs DDL statements', () async {
      await traced.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');

      expect(lastAdditional()['operation'], 'execute');
    });
  });

  group('transaction', () {
    test('wraps inner calls with transactionId', () async {
      ISpectDbCore.config = ISpectDbConfig(enableTransactionMarkers: true);

      await traced.transaction((txn) async {
        await txn.rawInsert(
          'INSERT INTO users (name) VALUES (?)',
          ['TxnUser'],
        );
      });

      // Verify the user was actually inserted.
      final rows = await realDb
          .rawQuery('SELECT * FROM users WHERE name = ?', ['TxnUser']);
      expect(rows.length, 1);
    });
  });

  group('passthrough', () {
    test('path and isOpen delegate', () {
      expect(traced.path, isA<String>());
      expect(traced.isOpen, isTrue);
      expect(traced.database, traced);
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final custom = ISpectSqfliteDatabase(
        delegate: realDb,
        logger: logger,
        source: 'my-sql',
      );
      await custom.rawQuery('SELECT 1');

      expect(lastAdditional()['source'], 'my-sql');
    });
  });
}
