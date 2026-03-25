import 'package:ispectify/ispectify.dart' hide Filter;
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/sembast_interceptor.dart';
import 'package:sembast/sembast.dart' as sembast show Database;
import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late sembast.Database db;
  late ISpectSembastStore<int, Map<String, Object?>> traced;

  setUp(() async {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();
    db = await newDatabaseFactoryMemory().openDatabase('test.db');
    traced = ISpectSembastStore(
      store: intMapStoreFactory.store('users'),
      logger: logger,
    );
  });

  tearDown(() async {
    await db.close();
    ISpectDbCore.config = ISpectDbConfig();
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('put', () {
    test('stores value and logs write', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});

      final value = await traced.get(db, 1);
      expect(value, containsPair('name', 'Alice'));

      // Check the put log (second to last, get is last).
      final putLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'write',
      );
      expect(putLog.additionalData?['source'], 'sembast');
      expect(putLog.additionalData?['table'], 'users');
      expect(putLog.additionalData?['key'], '1');
    });
  });

  group('get', () {
    test('reads value and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      final value = await traced.get(db, 1);

      expect(value, isNotNull);
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['key'], '1');
      expect(logger.history.last.key, 'db-query');
    });

    test('returns null for missing key', () async {
      final value = await traced.get(db, 999);
      expect(value, isNull);
    });
  });

  group('exists', () {
    test('checks existence and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      final exists = await traced.exists(db, 1);

      expect(exists, isTrue);
      expect(lastAdditional()['operation'], 'lookup');
    });
  });

  group('update', () {
    test('updates record and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      await traced.update(db, 1, {'name': 'Alice Updated'});

      final value = await traced.get(db, 1);
      expect(value, containsPair('name', 'Alice Updated'));

      final updateLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'update',
      );
      expect(updateLog.additionalData?['key'], '1');
    });
  });

  group('add', () {
    test('auto-key insert and logs', () async {
      final key = await traced.add(db, {'name': 'Charlie'});

      expect(key, isPositive);
      expect(
        logger.history
            .firstWhere(
              (e) => e.additionalData?['operation'] == 'insert',
            )
            .additionalData?['table'],
        'users',
      );
    });
  });

  group('deleteRecord', () {
    test('removes record and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      final deleted = await traced.deleteRecord(db, 1);

      expect(deleted, 1);
      expect(await traced.get(db, 1), isNull);
    });
  });

  group('find', () {
    test('finds records and logs count', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice', 'role': 'admin'});
      // ignore: avoid_dynamic_calls
      await traced.put(db, 2, {'name': 'Bob', 'role': 'user'});

      final all = await traced.find(db);
      expect(all.length, 2);

      final findLog = logger.history.lastWhere(
        (e) => e.additionalData?['operation'] == 'find',
      );
      expect(findLog.additionalData?['value'], contains('2'));
    });
  });

  group('count', () {
    test('counts records and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      // ignore: avoid_dynamic_calls
      await traced.put(db, 2, {'name': 'Bob'});

      final count = await traced.count(db);
      expect(count, 2);
      expect(lastAdditional()['operation'], 'count');
    });
  });

  group('store delete', () {
    test('deletes matching records and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      // ignore: avoid_dynamic_calls
      await traced.put(db, 2, {'name': 'Bob'});

      final deleted = await traced.delete(db);
      expect(deleted, 2);
    });
  });

  group('drop', () {
    test('drops store and logs', () async {
      // ignore: avoid_dynamic_calls
      await traced.put(db, 1, {'name': 'Alice'});
      await traced.drop(db);

      final count = await traced.count(db);
      expect(count, 0);
      expect(
        logger.history
            .any((e) => e.additionalData?['operation'] == 'clear'),
        isTrue,
      );
    });
  });

  group('transaction', () {
    test('wraps inner calls with transactionId', () async {
      ISpectDbCore.config = ISpectDbConfig(enableTransactionMarkers: true);

      await traced.transaction(db, (txn) async {
        await traced.put(txn, 10, {'name': 'TxnUser'});
      });

      final putLog = logger.history.lastWhere(
        (e) => e.additionalData?['operation'] == 'write',
      );
      expect(putLog.additionalData?['transactionId'], isNotNull);
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final custom = ISpectSembastStore(
        store: intMapStoreFactory.store('test'),
        logger: logger,
        source: 'sembast-web',
      );
      await custom.count(db);

      expect(lastAdditional()['source'], 'sembast-web');
    });
  });
}
