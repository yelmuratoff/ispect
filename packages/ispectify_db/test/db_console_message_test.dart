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

    test('returns null when no table is present', () {
      expect(DbSqlDigest.tableOf('PRAGMA foreign_keys = ON'), isNull);
      expect(DbSqlDigest.tableOf(null), isNull);
      expect(DbSqlDigest.tableOf(''), isNull);
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
