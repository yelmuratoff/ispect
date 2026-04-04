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
    db = await newDatabaseFactoryMemory().openDatabase('test.db');
    traced = intMapStoreFactory.store('users').traced(logger);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('record put', () {
    test('stores value and logs write', () async {
      await traced.record(1).put(db, {'name': 'Alice'});

      final value = await traced.record(1).get(db);
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

  group('record get', () {
    test('reads value and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      final value = await traced.record(1).get(db);

      expect(value, isNotNull);
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['key'], '1');
      expect(logger.history.last.key, 'db-query');
    });

    test('returns null for missing key', () async {
      final value = await traced.record(999).get(db);
      expect(value, isNull);
    });
  });

  group('record exists', () {
    test('checks existence and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      final exists = await traced.record(1).exists(db);

      expect(exists, isTrue);
      expect(lastAdditional()['operation'], 'lookup');
    });
  });

  group('record update', () {
    test('updates record and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      await traced.record(1).update(db, {'name': 'Alice Updated'});

      final value = await traced.record(1).get(db);
      expect(value, containsPair('name', 'Alice Updated'));

      final updateLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'update',
      );
      expect(updateLog.additionalData?['key'], '1');
    });
  });

  group('store add', () {
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

  group('record delete', () {
    test('removes record and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      final deleted = await traced.record(1).delete(db);

      expect(deleted, 1);
      expect(await traced.record(1).get(db), isNull);
    });
  });

  group('store find', () {
    test('finds records and logs count', () async {
      await traced.record(1).put(db, {'name': 'Alice', 'role': 'admin'});
      await traced.record(2).put(db, {'name': 'Bob', 'role': 'user'});

      final all = await traced.find(db);
      expect(all.length, 2);

      final findLog = logger.history.lastWhere(
        (e) => e.additionalData?['operation'] == 'find',
      );
      expect(findLog.additionalData?['value'], contains('2'));
    });
  });

  group('store count', () {
    test('counts records and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      await traced.record(2).put(db, {'name': 'Bob'});

      final count = await traced.count(db);
      expect(count, 2);
      expect(lastAdditional()['operation'], 'count');
    });
  });

  group('store delete', () {
    test('deletes matching records and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      await traced.record(2).put(db, {'name': 'Bob'});

      final deleted = await traced.delete(db);
      expect(deleted, 2);
    });
  });

  group('store drop', () {
    test('drops store and logs', () async {
      await traced.record(1).put(db, {'name': 'Alice'});
      await traced.drop(db);

      final count = await traced.count(db);
      expect(count, 0);
      expect(
        logger.history.any((e) => e.additionalData?['operation'] == 'clear'),
        isTrue,
      );
    });
  });

  group('transaction', () {
    test('wraps inner calls with transactionId', () async {
      final tracedWithMarkers = intMapStoreFactory.store('users').traced(
            logger,
            config: const ISpectDbConfig(enableTransactionMarkers: true),
          );

      await tracedWithMarkers.transaction(db, (txn) async {
        await tracedWithMarkers.record(10).put(txn, {'name': 'TxnUser'});
      });

      final putLog = logger.history.lastWhere(
        (e) => e.additionalData?['operation'] == 'write',
      );
      expect(putLog.additionalData?['transactionId'], isNotNull);
    });
  });

  group('convenience extension', () {
    test('.traced() creates store with correct source', () async {
      final custom = intMapStoreFactory
          .store('test')
          .traced(logger, source: 'sembast-web');
      await custom.count(db);

      expect(lastAdditional()['source'], 'sembast-web');
    });
  });

  group('implements StoreRef', () {
    test('can be used where StoreRef is expected', () {
      // Compile-time check: ISpectSembastStore IS a StoreRef.
      final StoreRef<int, Map<String, Object?>> storeRef = traced;
      expect(storeRef.name, 'users');
    });

    test('equality is name-based', () {
      final other = intMapStoreFactory.store('users');
      expect(traced == other, isTrue);
      expect(traced.hashCode, other.hashCode);
    });
  });

  group('implements RecordRef', () {
    test('record() returns ISpectSembastRecord', () {
      final record = traced.record(1);
      expect(record, isA<ISpectSembastRecord>());
      expect(record.key, 1);
      expect(record.store.name, 'users');
    });
  });
}
