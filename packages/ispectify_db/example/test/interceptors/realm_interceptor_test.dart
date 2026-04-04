import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db_example/interceptors/realm_interceptor.dart';
import 'package:ispectify_db_example/models/realm_task.dart';
import 'package:realm/realm.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late Realm realm;
  late ISpectRealm traced;

  setUp(() {
    logger = ISpectLogger();
    final config = Configuration.inMemory([RealmTask.schema]);
    realm = Realm(config);
    traced = ISpectRealm(delegate: realm, logger: logger);
  });

  tearDown(() {
    if (!realm.isClosed) {
      realm.close();
    }
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  // --- Reads ----------------------------------------------------------------

  group('find', () {
    test('returns object and logs cache hit', () {
      final id = ObjectId();
      realm.write(() => realm.add(RealmTask(id, 'Hello')));

      final result = traced.find<RealmTask>(id);

      expect(result?.title, 'Hello');
      expect(lastAdditional()['source'], 'realm');
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['table'], 'RealmTask');
      expect(lastAdditional()['cacheHit'], isTrue);
      expect(logger.history.last.key, 'db-query');
    });

    test('logs cache miss for missing id', () {
      final result = traced.find<RealmTask>(ObjectId());

      expect(result, isNull);
      expect(lastAdditional()['cacheHit'], isFalse);
    });
  });

  group('all', () {
    test('returns all and logs count', () {
      realm.write(() {
        realm.add(RealmTask(ObjectId(), 'A'));
        realm.add(RealmTask(ObjectId(), 'B'));
      });

      final results = traced.all<RealmTask>();

      expect(results.length, 2);
      expect(lastAdditional()['operation'], 'query');
      expect(lastAdditional()['table'], 'RealmTask');
      expect(logger.history.last.key, 'db-query');
    });
  });

  group('query', () {
    test('returns filtered results and logs statement', () {
      realm.write(() {
        realm.add(RealmTask(ObjectId(), 'Done', isComplete: true));
        realm.add(RealmTask(ObjectId(), 'Pending'));
      });

      final results = traced.query<RealmTask>('isComplete == \$0', [true]);

      expect(results.length, 1);
      expect(results.first.title, 'Done');
      expect(lastAdditional()['operation'], 'query');
      expect(lastAdditional()['statement'], isNotNull);
    });
  });

  // --- Writes ---------------------------------------------------------------

  group('add', () {
    test('stores and logs write', () {
      traced.write(() {
        traced.add(RealmTask(ObjectId(), 'New'));
      });

      expect(realm.all<RealmTask>().length, 1);

      final writeLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'write')
          .toList();
      expect(writeLogs, isNotEmpty);
      expect(writeLogs.last.additionalData?['table'], 'RealmTask');
      expect(writeLogs.last.key, 'db-result');
    });
  });

  group('addAll', () {
    test('stores multiple and logs count', () {
      traced.write(() {
        traced.addAll([
          RealmTask(ObjectId(), 'X'),
          RealmTask(ObjectId(), 'Y'),
        ]);
      });

      expect(realm.all<RealmTask>().length, 2);

      final writeLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'write')
          .toList();
      expect(writeLogs.last.additionalData?['meta'], containsPair('count', 2));
    });
  });

  // --- Deletes --------------------------------------------------------------

  group('delete', () {
    test('removes and logs', () {
      final id = ObjectId();
      realm.write(() => realm.add(RealmTask(id, 'Tmp')));

      traced.write(() {
        final task = traced.find<RealmTask>(id)!;
        traced.delete(task);
      });

      expect(realm.all<RealmTask>().length, 0);

      final deleteLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'delete')
          .toList();
      expect(deleteLogs, isNotEmpty);
      expect(deleteLogs.last.key, 'db-result');
    });
  });

  group('deleteMany', () {
    test('removes multiple and logs', () {
      realm.write(() {
        realm.add(RealmTask(ObjectId(), 'A'));
        realm.add(RealmTask(ObjectId(), 'B'));
      });

      traced.write(() {
        final all = traced.all<RealmTask>();
        traced.deleteMany(all.toList());
      });

      expect(realm.all<RealmTask>().length, 0);

      final deleteLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'delete')
          .toList();
      expect(deleteLogs.last.additionalData?['meta'], containsPair('count', 2));
    });
  });

  group('deleteAll', () {
    test('clears all and logs', () {
      realm.write(() {
        realm.add(RealmTask(ObjectId(), 'A'));
        realm.add(RealmTask(ObjectId(), 'B'));
      });

      traced.write(() {
        traced.deleteAll<RealmTask>();
      });

      expect(realm.all<RealmTask>().length, 0);

      final clearLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'clear')
          .toList();
      expect(clearLogs, isNotEmpty);
      expect(clearLogs.last.additionalData?['table'], 'RealmTask');
    });
  });

  // --- Transactions ---------------------------------------------------------

  group('write', () {
    test('traces transaction duration', () {
      traced.write(() {
        traced.add(RealmTask(ObjectId(), 'In txn'));
      });

      final txnLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'transaction')
          .toList();
      expect(txnLogs, isNotEmpty);
      expect(txnLogs.last.additionalData?['source'], 'realm');
      expect(txnLogs.last.key, 'db-result');
    });

    test('returns callback result', () {
      final id = ObjectId();
      final result = traced.write(() {
        return traced.add(RealmTask(id, 'Return me'));
      });

      expect(result.title, 'Return me');
    });
  });

  group('writeAsync', () {
    test('traces async transaction', () async {
      await traced.writeAsync(() {
        traced.delegate.add(RealmTask(ObjectId(), 'Async'));
      });

      final txnLogs = logger.history
          .where((e) => e.additionalData?['operation'] == 'transaction')
          .toList();
      expect(txnLogs, isNotEmpty);
    });
  });

  // --- Custom source --------------------------------------------------------

  group('custom source', () {
    test('uses provided source', () {
      final custom = ISpectRealm(
        delegate: realm,
        logger: logger,
        source: 'realm-v20',
      );

      custom.find<RealmTask>(ObjectId());
      expect(lastAdditional()['source'], 'realm-v20');
    });
  });

  // --- Delegate access ------------------------------------------------------

  group('delegate', () {
    test('exposes underlying Realm', () {
      expect(traced.delegate, same(realm));
    });
  });

  // --- Drop-in --------------------------------------------------------------

  group('drop-in', () {
    test('assignable to Realm', () {
      // ignore: omit_local_variable_types
      final Realm r = traced;
      expect(r, isA<Realm>());
    });

    test('equality with delegate', () {
      expect(traced == realm, isTrue);
    });
  });

  // --- Passthrough ----------------------------------------------------------

  group('passthrough', () {
    test('isClosed reflects delegate state', () {
      expect(traced.isClosed, isFalse);
      realm.close();
      expect(traced.isClosed, isTrue);
    });

    test('isInTransaction reflects delegate state', () {
      expect(traced.isInTransaction, isFalse);
    });

    test('config matches delegate', () {
      expect(traced.config, same(realm.config));
    });

    test('schema matches delegate', () {
      expect(traced.schema, same(realm.schema));
    });

    test('freeze returns traced wrapper', () {
      final frozen = traced.freeze();
      expect(frozen, isA<ISpectRealm>());
      expect(frozen.isFrozen, isTrue);
      frozen.delegate.close();
    });
  });
}
