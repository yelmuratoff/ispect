import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:test/test.dart';

ISpectLogger _logger() => ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 20),
    );

void main() {
  setUp(() {
    ISpectRedaction.reset();
    ISpectRedaction.configure(service: RedactionService());
  });

  tearDown(ISpectRedaction.reset);

  group('DbSqlDigest.tableOf', () {
    test('reads the table from each statement family', () {
      expect(
        DbSqlDigest.tableOf('SELECT * FROM users WHERE id = ?'),
        'users',
      );
      expect(
        DbSqlDigest.tableOf('INSERT INTO orders (id) VALUES (?)'),
        'orders',
      );
      expect(DbSqlDigest.tableOf('UPDATE carts SET total = ?'), 'carts');
      expect(
        DbSqlDigest.tableOf('DELETE FROM sessions WHERE id = ?'),
        'sessions',
      );
    });

    test('does not mistake a quoted literal for a table', () {
      expect(
        DbSqlDigest.tableOf("SELECT * FROM users WHERE name = 'from secret'"),
        'users',
      );
    });

    test('reads a table quoted as an identifier', () {
      expect(
        DbSqlDigest.tableOf('DELETE FROM "sessions" WHERE "id" = ?'),
        'sessions',
      );
      expect(
        DbSqlDigest.tableOf('SELECT * FROM `carts` WHERE `id` = ?'),
        'carts',
      );
    });

    test('returns null when no table is present', () {
      expect(DbSqlDigest.tableOf('PRAGMA foreign_keys = ON'), isNull);
      expect(DbSqlDigest.tableOf(null), isNull);
      expect(DbSqlDigest.tableOf(''), isNull);
    });
  });

  group('DbSqlDigest.normalize', () {
    test('keeps quoted identifiers so the statement stays readable', () {
      expect(
        DbSqlDigest.normalize('DELETE FROM "cache" WHERE "key" LIKE ?;'),
        'DELETE FROM "cache" WHERE "key" LIKE ?;',
      );
      expect(
        DbSqlDigest.normalize('SELECT `total` FROM `carts`'),
        'SELECT `total` FROM `carts`',
      );
    });

    test('masks single-quoted literals and digits', () {
      expect(
        DbSqlDigest.normalize(
          "UPDATE \"carts\" SET \"token\" = 'SQL_SECRET' WHERE \"id\" = 41",
        ),
        'UPDATE "carts" SET "token" = ? WHERE "id" = ?',
      );
    });

    test('masks a double-quoted span that is not a plain identifier', () {
      expect(
        DbSqlDigest.normalize('INSERT INTO t VALUES ("some secret value")'),
        'INSERT INTO t VALUES (?)',
      );
      expect(
        DbSqlDigest.normalize('SELECT * FROM t WHERE a = "user@example.com"'),
        'SELECT * FROM t WHERE a = ?',
      );
      expect(
        DbSqlDigest.normalize('SELECT "${'a' * 65}" FROM t'),
        'SELECT ? FROM t',
      );
    });

    test('masks unterminated and escaped quoted spans', () {
      expect(
        DbSqlDigest.normalize('SELECT * FROM t WHERE a = "DQS_SECRET'),
        'SELECT * FROM t WHERE a = ?',
      );
      expect(
        DbSqlDigest.normalize('SELECT "esc""aped" FROM t'),
        'SELECT ? FROM t',
      );
    });
  });

  group('database console message', () {
    test('names the table and affected rows without the caller passing one',
        () async {
      final logger = _logger();
      addTearDown(logger.dispose);

      await logger.dbTrace<int>(
        source: 'drift',
        operation: 'delete',
        statement: 'DELETE FROM sessions WHERE id = ?',
        args: <Object?>[7],
        run: () async => 3,
        projectResult: (n) => <String, Object?>{'affected': n},
      );

      final text = logger.history.single.textMessage;
      expect(text, contains('delete sessions'));
      expect(text, isNot(contains('unprintable')));
    });

    test('shows the normalized statement without its literals', () async {
      final logger = _logger();
      addTearDown(logger.dispose);

      await logger.dbTrace<int>(
        source: 'drift',
        operation: 'update',
        statement: "UPDATE carts SET token = 'SQL_SECRET' WHERE id = 41",
        args: <Object?>[1],
        run: () async => 1,
      );

      final text = logger.history.single.textMessage;
      expect(text, contains('update carts'));
      expect(text, contains('UPDATE carts SET token'));
      expect(text, isNot(contains('SQL_SECRET')));
      expect(text, isNot(contains('41')));
    });

    test('reports affected rows returned by projectResult', () async {
      final logger = _logger();
      addTearDown(logger.dispose);

      await logger.dbTrace<int>(
        source: 'drift',
        operation: 'insert',
        statement: 'INSERT INTO users (id) VALUES (?)',
        args: <Object?>[1],
        run: () async => 5,
        projectResult: (n) => <String, Object?>{'affected': n},
      );

      expect(logger.history.single.textMessage, contains('Affected: 5'));
    });

    test('names the table for a drift statement quoting its identifiers',
        () async {
      final logger = _logger();
      addTearDown(logger.dispose);

      await logger.dbTrace<int>(
        source: 'drift',
        operation: 'delete',
        statement: 'DELETE FROM "cache_entries" WHERE "key" LIKE ?;',
        args: <Object?>['prefix%'],
        run: () async => 0,
        projectResult: (n) => <String, Object?>{'affected': n},
      );

      final text = logger.history.single.textMessage;
      expect(text, contains('delete cache_entries'));
      expect(text, contains('DELETE FROM "cache_entries" WHERE "key" LIKE ?;'));
    });

    test('masks an unquoted SQLCipher key operand', () async {
      final logger = _logger();
      addTearDown(logger.dispose);

      await logger.dbTrace<void>(
        source: 'drift',
        operation: 'execute',
        statement: 'PRAGMA key = SQLCIPHER_SECRET',
        run: () async {},
      );

      final text = logger.history.single.textMessage;
      expect(text, isNot(contains('SQLCIPHER_SECRET')));
      expect(text, contains('PRAGMA key = [REDACTED]'));
    });
  });
}
