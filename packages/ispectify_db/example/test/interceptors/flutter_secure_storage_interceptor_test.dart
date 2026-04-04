import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db_example/interceptors/flutter_secure_storage_interceptor.dart';

void main() {
  late ISpectLogger logger;
  late FlutterSecureStorage storage;
  late ISpectSecureStorage traced;

  /// In-memory store for mocked platform channel.
  final mockStore = <String, String>{};

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock the platform channel to avoid real keychain/keystore calls.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = call.arguments as Map?;
        switch (call.method) {
          case 'read':
            return mockStore[args!['key'] as String];
          case 'write':
            mockStore[args!['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            mockStore.remove(args!['key'] as String);
            return null;
          case 'deleteAll':
            mockStore.clear();
            return null;
          case 'readAll':
            return mockStore;
          case 'containsKey':
            return mockStore.containsKey(args!['key'] as String);
          default:
            return null;
        }
      },
    );

    mockStore
      ..clear()
      ..['token'] = 'secret-jwt';

    logger = ISpectLogger();
    storage = const FlutterSecureStorage();
    traced = ISpectSecureStorage(delegate: storage, logger: logger);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('read', () {
    test('reads from real storage and logs', () async {
      final value = await traced.read(key: 'token');

      expect(value, 'secret-jwt');
      expect(lastAdditional()['source'], 'secure_storage');
      expect(lastAdditional()['operation'], 'read');
      expect(lastAdditional()['key'], 'token');
      // Projection redacts value.
      expect(lastAdditional()['value'], contains('***'));
    });

    test('returns null for missing key', () async {
      expect(await traced.read(key: 'missing'), isNull);
    });
  });

  group('write', () {
    test('writes to storage and logs', () async {
      await traced.write(key: 'pin', value: '1234');

      expect(mockStore['pin'], '1234');
      expect(lastAdditional()['operation'], 'write');
      expect(lastAdditional()['key'], 'pin');
    });
  });

  group('delete', () {
    test('removes key and logs', () async {
      await traced.delete(key: 'token');

      expect(mockStore.containsKey('token'), isFalse);
      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('deleteAll', () {
    test('clears and logs', () async {
      await traced.deleteAll();

      expect(mockStore, isEmpty);
      expect(lastAdditional()['operation'], 'clear');
    });
  });

  group('readAll', () {
    test('returns all and logs count', () async {
      mockStore['pin'] = '5678';
      final all = await traced.readAll();

      expect(all.length, 2);
      expect(lastAdditional()['operation'], 'list');
    });
  });

  group('containsKey', () {
    test('checks and logs', () async {
      final exists = await traced.containsKey(key: 'token');

      expect(exists, isTrue);
      expect(lastAdditional()['operation'], 'lookup');
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final custom = ISpectSecureStorage(
        delegate: storage,
        logger: logger,
        source: 'keychain',
      );
      await custom.read(key: 'token');

      expect(lastAdditional()['source'], 'keychain');
    });
  });
}
