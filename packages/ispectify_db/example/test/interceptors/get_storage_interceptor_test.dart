import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/get_storage_interceptor.dart';

void main() {
  late ISpectLogger logger;
  late ISpectGetStorage traced;
  late Directory tempDir;
  late GetStorage box;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('get_storage_test_');

    // Mock path_provider — GetStorage internally calls
    // getApplicationDocumentsDirectory even when a custom path is provided.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );

    // Use unique container name per test to avoid singleton cache conflicts.
    final containerName = 'test_${tempDir.hashCode}';
    box = GetStorage(containerName, tempDir.path);
    await box.initStorage;
    await box.erase();

    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();
    traced = ISpectGetStorage(
      delegate: box,
      logger: logger,
      containerName: 'test',
    );
  });

  tearDown(() async {
    ISpectDbCore.config = ISpectDbConfig();
    // Allow background flushes to settle before clearing mock.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('reads', () {
    test('read logs with cache hit when key exists', () async {
      await traced.write('theme', 'dark');
      final value = traced.read<String>('theme');

      expect(value, 'dark');
      expect(lastAdditional()['source'], 'get_storage');
      expect(lastAdditional()['operation'], 'read');
      expect(lastAdditional()['key'], 'theme');
      expect(lastAdditional()['cacheHit'], isTrue);
    });

    test('read logs cache miss for absent key', () {
      expect(traced.read<String>('missing'), isNull);
      expect(lastAdditional()['operation'], 'read');
      expect(lastAdditional()['cacheHit'], isFalse);
    });

    test('hasData logs lookup', () async {
      await traced.write('flag', true);
      final result = traced.hasData('flag');

      expect(result, isTrue);
      expect(lastAdditional()['operation'], 'lookup');
      expect(lastAdditional()['cacheHit'], isTrue);
    });

    test('hasData logs miss for absent key', () {
      expect(traced.hasData('nope'), isFalse);
      expect(lastAdditional()['operation'], 'lookup');
      expect(lastAdditional()['cacheHit'], isFalse);
    });

    test('getKeys logs list with count', () async {
      await traced.write('a', 1);
      await traced.write('b', 2);
      final keys = traced.getKeys<Iterable<String>>();

      expect(keys, containsAll(['a', 'b']));
      expect(lastAdditional()['operation'], 'list');
      expect(lastAdditional()['items'], greaterThanOrEqualTo(2));
    });

    test('getValues logs list with count', () async {
      await traced.write('x', 10);
      final values = traced.getValues<Iterable<dynamic>>();

      expect(values, isNotEmpty);
      expect(lastAdditional()['operation'], 'list');
      expect(lastAdditional()['items'], isPositive);
    });
  });

  group('writes', () {
    test('write stores value and logs', () async {
      await traced.write('lang', 'en');

      expect(traced.read<String>('lang'), 'en');

      final writeLog = logger.history.firstWhere(
        (e) =>
            e.additionalData?['operation'] == 'write' &&
            e.additionalData?['key'] == 'lang',
      );
      expect(writeLog.additionalData?['source'], 'get_storage');
    });

    test('writeInMemory logs with memoryOnly meta', () {
      traced.writeInMemory('temp', 'value');

      expect(traced.read<String>('temp'), 'value');

      final writeLog = logger.history.firstWhere(
        (e) =>
            e.additionalData?['operation'] == 'write' &&
            e.additionalData?['key'] == 'temp',
      );
      expect(writeLog.additionalData?['source'], 'get_storage');
    });

    test('writeIfNull logs write', () async {
      await traced.writeIfNull('new_key', 'initial');

      expect(traced.read<String>('new_key'), 'initial');

      final writeLog = logger.history.firstWhere(
        (e) =>
            e.additionalData?['operation'] == 'write' &&
            e.additionalData?['key'] == 'new_key',
      );
      expect(writeLog.additionalData?['source'], 'get_storage');
    });
  });

  group('deletes', () {
    test('remove logs delete', () async {
      await traced.write('to_delete', 'bye');
      await traced.remove('to_delete');

      expect(traced.hasData('to_delete'), isFalse);

      final deleteLog = logger.history.firstWhere(
        (e) =>
            e.additionalData?['operation'] == 'delete' &&
            e.additionalData?['key'] == 'to_delete',
      );
      expect(deleteLog.additionalData?['source'], 'get_storage');
    });

    test('erase logs clear', () async {
      await traced.write('a', 1);
      await traced.write('b', 2);
      await traced.erase();

      expect(traced.getKeys<Iterable<String>>(), isEmpty);

      final clearLog = logger.history.firstWhere(
        (e) => e.additionalData?['operation'] == 'clear',
      );
      expect(clearLog.additionalData?['source'], 'get_storage');
    });
  });

  group('container name', () {
    test('logs table as container name', () async {
      await traced.write('k', 'v');

      final writeLog = logger.history.firstWhere(
        (e) =>
            e.additionalData?['operation'] == 'write' &&
            e.additionalData?['key'] == 'k',
      );
      expect(writeLog.additionalData?['table'], 'test');
    });
  });

  group('custom source', () {
    test('uses provided source', () {
      final custom = ISpectGetStorage(
        delegate: box,
        logger: logger,
        source: 'my_storage',
      );
      custom.read<String>('theme');

      expect(lastAdditional()['source'], 'my_storage');
    });
  });

  group('drop-in', () {
    test('type assignable to GetStorage', () {
      // ignore: omit_local_variable_types
      final GetStorage gs = traced;
      expect(gs, isA<GetStorage>());
    });
  });

  group('delegate', () {
    test('exposes underlying GetStorage', () {
      expect(traced.delegate, isA<GetStorage>());
    });
  });

  group('observation passthrough', () {
    test('listen fires on write', () async {
      var fired = false;
      final dispose = traced.listen(() => fired = true);

      await traced.write('trigger', 'go');
      expect(fired, isTrue);

      dispose();
    });

    test('listenKey fires for specific key', () async {
      dynamic receivedValue;
      final dispose = traced.listenKey('watched', (val) {
        receivedValue = val;
      });

      await traced.write('watched', 'new_value');
      expect(receivedValue, 'new_value');

      dispose();
    });

    test('changes reflects last write', () async {
      await traced.write('last', 'change');
      expect(traced.changes, containsPair('last', 'change'));
    });
  });
}
