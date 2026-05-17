import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db_example/interceptors/hive_interceptor.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late Directory tempDir;
  late Box<String> realBox;
  late ISpectHiveBox<String> traced;

  setUp(() async {
    logger = ISpectLogger();
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    realBox = await Hive.openBox<String>('test');
    traced = ISpectHiveBox(delegate: realBox, logger: logger);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('get', () {
    test('returns value and logs cache hit', () async {
      await realBox.put('k', 'v');
      final value = traced.get('k');

      expect(value, 'v');
      expect(lastAdditional()['source'], 'hive');
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['cacheHit'], isTrue);
      expect(logger.history.last.key, 'db-query');
    });

    test('logs cache miss', () {
      traced.get('missing');
      expect(lastAdditional()['cacheHit'], isFalse);
    });
  });

  group('getAt', () {
    test('returns value at index', () async {
      await realBox.put('a', 'A');
      final value = traced.getAt(0);

      expect(value, 'A');
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['key'], 'index:0');
    });
  });

  group('containsKey', () {
    test('logs lookup', () async {
      await realBox.put('k', 'v');
      expect(traced.containsKey('k'), isTrue);
      expect(lastAdditional()['operation'], 'lookup');
      expect(lastAdditional()['cacheHit'], isTrue);
    });
  });

  group('put', () {
    test('stores and logs write', () async {
      await traced.put('x', 'X');

      expect(realBox.get('x'), 'X');
      expect(lastAdditional()['operation'], 'write');
      expect(lastAdditional()['key'], 'x');
    });
  });

  group('putAll', () {
    test('stores all and logs', () async {
      await traced.putAll({'a': 'A', 'b': 'B'});

      expect(realBox.get('a'), 'A');
      expect(lastAdditional()['operation'], 'write');
    });
  });

  group('add', () {
    test('auto-key insert', () async {
      final key = await traced.add('auto');

      expect(key, isA<int>());
      expect(lastAdditional()['operation'], 'insert');
    });
  });

  group('addAll', () {
    test('bulk auto-key insert', () async {
      final keys = await traced.addAll(['x', 'y', 'z']);

      expect(keys.length, 3);
      expect(lastAdditional()['operation'], 'insert');
    });
  });

  group('delete', () {
    test('removes key and logs', () async {
      await realBox.put('k', 'v');
      await traced.delete('k');

      expect(realBox.containsKey('k'), isFalse);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('deleteAll', () {
    test('removes keys and logs', () async {
      await realBox.putAll({'a': 'A', 'b': 'B'});
      await traced.deleteAll(['a', 'b']);

      expect(realBox.isEmpty, isTrue);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('clear', () {
    test('clears and logs count', () async {
      await realBox.putAll({'a': 'A', 'b': 'B'});
      final cleared = await traced.clear();

      expect(cleared, 2);
      expect(realBox.isEmpty, isTrue);
      expect(lastAdditional()['operation'], 'clear');
    });
  });

  group('passthrough', () {
    test('name, keys, values, length, isEmpty delegate', () async {
      await realBox.put('k', 'v');

      expect(traced.name, 'test');
      expect(traced.keys, contains('k'));
      expect(traced.values, contains('v'));
      expect(traced.length, 1);
      expect(traced.isEmpty, isFalse);
      expect(traced.isNotEmpty, isTrue);
      expect(traced.isOpen, isTrue);
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      ISpectHiveBox(
        delegate: realBox,
        logger: logger,
        source: 'hive-ce',
      ).get('k');

      expect(lastAdditional()['source'], 'hive-ce');
    });
  });
}
