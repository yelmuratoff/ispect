import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db_example/interceptors/isar_interceptor.dart';
import 'package:ispectify_db_example/models/isar_user.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late Directory tempDir;
  late Isar isar;
  late ISpectIsarCollection<IsarUser> traced;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    logger = ISpectLogger();
    tempDir = Directory.systemTemp.createTempSync('isar_test_');
    isar = await Isar.open([IsarUserSchema], directory: tempDir.path);
    traced = ISpectIsarCollection(
      delegate: isar.isarUsers,
      logger: logger,
      collectionName: 'users',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('get', () {
    test('returns object and logs', () async {
      final user = IsarUser()..name = 'Alice';
      late int id;
      await isar.writeTxn(() async {
        id = await isar.isarUsers.put(user);
      });

      final result = await traced.get(id);

      expect(result?.name, 'Alice');
      expect(lastAdditional()['source'], 'isar');
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['table'], 'users');
      expect(logger.history.last.key, 'db-query');
    });

    test('returns null for missing id', () async {
      final result = await traced.get(999);
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns list and logs', () async {
      await isar.writeTxn(() async {
        await isar.isarUsers
            .putAll([IsarUser()..name = 'A', IsarUser()..name = 'B']);
      });

      final results = await traced.getAll([1, 2, 999]);
      expect(results.length, 3);
      expect(results.where((e) => e != null).length, 2);
    });
  });

  group('put', () {
    test('inserts and logs with id', () async {
      late Id id;
      await isar.writeTxn(() async {
        id = await traced.put(IsarUser()..name = 'Eve');
      });

      expect(id, isPositive);
      expect(lastAdditional()['operation'], 'insert');
      expect(lastAdditional()['table'], 'users');
    });
  });

  group('putAll', () {
    test('bulk inserts and logs count', () async {
      late List<Id> ids;
      await isar.writeTxn(() async {
        ids = await traced.putAll([
          IsarUser()..name = 'X',
          IsarUser()..name = 'Y',
          IsarUser()..name = 'Z',
        ]);
      });

      expect(ids.length, 3);
      expect(lastAdditional()['operation'], 'insert');
    });
  });

  group('delete', () {
    test('removes and logs', () async {
      late Id id;
      await isar.writeTxn(() async {
        id = await isar.isarUsers.put(IsarUser()..name = 'Tmp');
      });

      late bool deleted;
      await isar.writeTxn(() async {
        deleted = await traced.delete(id);
      });

      expect(deleted, isTrue);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('deleteAll', () {
    test('removes multiple and logs', () async {
      await isar.writeTxn(() async {
        await isar.isarUsers
            .putAll([IsarUser()..name = 'A', IsarUser()..name = 'B']);
      });

      late int count;
      await isar.writeTxn(() async {
        count = await traced.deleteAll([1, 2, 999]);
      });

      expect(count, 2);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('clear', () {
    test('clears collection and logs', () async {
      await isar.writeTxn(() async {
        await isar.isarUsers.put(IsarUser()..name = 'A');
      });

      await isar.writeTxn(() async {
        await traced.clear();
      });

      final count = await isar.isarUsers.count();
      expect(count, 0);
      expect(lastAdditional()['operation'], 'clear');
    });
  });

  group('count', () {
    test('returns count and logs', () async {
      await isar.writeTxn(() async {
        await isar.isarUsers
            .putAll([IsarUser()..name = 'A', IsarUser()..name = 'B']);
      });

      final n = await traced.count();
      expect(n, 2);
      expect(lastAdditional()['operation'], 'count');
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final custom = ISpectIsarCollection(
        delegate: isar.isarUsers,
        logger: logger,
        collectionName: 'users',
        source: 'isar-v4',
      );
      await custom.get(1);

      expect(lastAdditional()['source'], 'isar-v4');
    });
  });
}
