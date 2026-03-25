import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/objectbox_interceptor.dart';
import 'package:ispectify_db_example/models/objectbox_task.dart';
import 'package:ispectify_db_example/objectbox.g.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late Directory tempDir;
  late Store store;
  late Box<ObjectBoxTask> realBox;
  late ISpectObjectBox<ObjectBoxTask> traced;

  setUp(() async {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();
    tempDir = Directory.systemTemp.createTempSync('objectbox_test_');
    store = await openStore(directory: tempDir.path);
    realBox = store.box<ObjectBoxTask>();
    traced = ISpectObjectBox(
      delegate: realBox,
      logger: logger,
      boxName: 'Task',
    );
  });

  tearDown(() {
    store.close();
    ISpectDbCore.config = ISpectDbConfig();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  // --- Sync reads -----------------------------------------------------------

  group('get', () {
    test('returns object and logs cache hit', () {
      final id = realBox.put(ObjectBoxTask()..text = 'Hello');
      final result = traced.get(id);

      expect(result?.text, 'Hello');
      expect(lastAdditional()['source'], 'objectbox');
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['table'], 'Task');
      expect(lastAdditional()['cacheHit'], isTrue);
      expect(logger.history.last.key, 'db-query');
    });

    test('logs cache miss for missing id', () {
      final result = traced.get(999);
      expect(result, isNull);
      expect(lastAdditional()['cacheHit'], isFalse);
    });
  });

  group('getMany', () {
    test('returns list and logs', () {
      realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      final results = traced.getMany([1, 2, 999]);
      expect(results.where((e) => e != null).length, 2);
      expect(lastAdditional()['operation'], 'getMany');
      expect(lastAdditional()['table'], 'Task');
    });
  });

  group('getAll', () {
    test('returns all and logs count', () {
      realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      final results = traced.getAll();
      expect(results.length, 2);
      expect(lastAdditional()['operation'], 'getAll');
    });
  });

  // --- Async reads ----------------------------------------------------------

  group('getAsync', () {
    test('returns object and logs', () async {
      final id = realBox.put(ObjectBoxTask()..text = 'Async');
      final result = await traced.getAsync(id);

      expect(result?.text, 'Async');
      expect(lastAdditional()['source'], 'objectbox');
      expect(lastAdditional()['operation'], 'getAsync');
      expect(logger.history.last.key, 'db-result');
    });
  });

  group('getAllAsync', () {
    test('returns all and logs', () async {
      realBox.put(ObjectBoxTask()..text = 'One');
      final results = await traced.getAllAsync();

      expect(results.length, 1);
      expect(lastAdditional()['operation'], 'getAllAsync');
    });
  });

  // --- Sync writes ----------------------------------------------------------

  group('put', () {
    test('stores and logs with id', () {
      final id = traced.put(ObjectBoxTask()..text = 'New');

      expect(id, isPositive);
      expect(realBox.get(id)?.text, 'New');
      expect(lastAdditional()['operation'], 'put');
      expect(lastAdditional()['table'], 'Task');
      expect(logger.history.last.key, 'db-result');
    });
  });

  group('putMany', () {
    test('bulk stores and logs count', () {
      final ids = traced.putMany([
        ObjectBoxTask()..text = 'X',
        ObjectBoxTask()..text = 'Y',
      ]);

      expect(ids.length, 2);
      expect(lastAdditional()['operation'], 'putMany');
    });
  });

  // --- Async writes ---------------------------------------------------------

  group('putAsync', () {
    test('stores and logs', () async {
      final id = await traced.putAsync(ObjectBoxTask()..text = 'AsyncPut');

      expect(id, isPositive);
      expect(lastAdditional()['operation'], 'putAsync');
    });
  });

  group('putManyAsync', () {
    test('bulk stores and logs', () async {
      final ids = await traced.putManyAsync([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      expect(ids.length, 2);
      expect(lastAdditional()['operation'], 'putManyAsync');
    });
  });

  // --- Sync deletes ---------------------------------------------------------

  group('remove', () {
    test('removes and logs', () {
      final id = realBox.put(ObjectBoxTask()..text = 'Tmp');
      final deleted = traced.remove(id);

      expect(deleted, isTrue);
      expect(realBox.get(id), isNull);
      expect(lastAdditional()['operation'], 'delete');
      expect(logger.history.last.key, 'db-result');
    });
  });

  group('removeMany', () {
    test('removes multiple and logs', () {
      final ids = realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      final count = traced.removeMany(ids);
      expect(count, 2);
      expect(lastAdditional()['operation'], 'deleteMany');
    });
  });

  group('removeAll', () {
    test('clears box and logs count', () {
      realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      final cleared = traced.removeAll();
      expect(cleared, 2);
      expect(realBox.isEmpty(), isTrue);
      expect(lastAdditional()['operation'], 'clear');
    });
  });

  // --- Async deletes --------------------------------------------------------

  group('removeAsync', () {
    test('removes and logs', () async {
      final id = realBox.put(ObjectBoxTask()..text = 'Tmp');
      final deleted = await traced.removeAsync(id);

      expect(deleted, isTrue);
      expect(lastAdditional()['operation'], 'deleteAsync');
    });
  });

  group('removeManyAsync', () {
    test('removes multiple and logs', () async {
      final ids = realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      final count = await traced.removeManyAsync(ids);
      expect(count, 2);
      expect(lastAdditional()['operation'], 'deleteManyAsync');
    });
  });

  group('removeAllAsync', () {
    test('clears and logs', () async {
      realBox.put(ObjectBoxTask()..text = 'A');
      final cleared = await traced.removeAllAsync();

      expect(cleared, 1);
      expect(lastAdditional()['operation'], 'clearAsync');
    });
  });

  // --- Aggregations ---------------------------------------------------------

  group('count', () {
    test('returns count and logs', () {
      realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      final n = traced.count();
      expect(n, 2);
      expect(lastAdditional()['operation'], 'count');
    });
  });

  group('isEmpty', () {
    test('returns true when empty', () {
      expect(traced.isEmpty(), isTrue);
      expect(lastAdditional()['operation'], 'lookup');
    });
  });

  group('contains', () {
    test('logs lookup with cache hit', () {
      final id = realBox.put(ObjectBoxTask()..text = 'X');

      expect(traced.contains(id), isTrue);
      expect(lastAdditional()['operation'], 'lookup');
      expect(lastAdditional()['cacheHit'], isTrue);
    });

    test('logs lookup with cache miss', () {
      expect(traced.contains(999), isFalse);
      expect(lastAdditional()['cacheHit'], isFalse);
    });
  });

  group('containsMany', () {
    test('logs lookup', () {
      final ids = realBox.putMany([
        ObjectBoxTask()..text = 'A',
        ObjectBoxTask()..text = 'B',
      ]);

      expect(traced.containsMany(ids), isTrue);
      expect(lastAdditional()['operation'], 'lookup');
    });
  });

  // --- Custom source --------------------------------------------------------

  group('custom source', () {
    test('uses provided source', () {
      final custom = ISpectObjectBox(
        delegate: realBox,
        logger: logger,
        boxName: 'Task',
        source: 'objectbox-v4',
      );
      custom.get(1);

      expect(lastAdditional()['source'], 'objectbox-v4');
    });
  });

  // --- Delegate access ------------------------------------------------------

  group('delegate', () {
    test('exposes underlying Box', () {
      expect(traced.delegate, same(realBox));
    });
  });

  // --- Query passthrough ----------------------------------------------------

  group('query', () {
    test('returns a query builder from delegate', () {
      realBox.put(ObjectBoxTask()..text = 'Find me');
      final builder = traced.query();
      final query = builder.build();
      final results = query.find();

      expect(results.length, 1);
      expect(results.first.text, 'Find me');
      query.close();
    });
  });

  // --- Drop-in ----------------------------------------------------------------

  group('drop-in', () {
    test('assignable to Box<T>', () {
      // ignore: omit_local_variable_types
      final Box<ObjectBoxTask> box = traced;
      expect(box, isA<Box<ObjectBoxTask>>());
    });
  });
}
