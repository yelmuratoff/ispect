/// Example: FlutterSecureStorage interceptor with real package.
///
/// Requires Flutter context. Run via `flutter test` or in a Flutter app.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/flutter_secure_storage_interceptor.dart';

Future<void> secureStorageExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  FlutterSecureStorage delegate = const FlutterSecureStorage();

  // On macOS, secure storage often fails with -34018 if the app isn't signed.
  // We check if it works, and if not, we use an in-memory fallback
  // so the example remains runnable and demonstrates the logging.
  try {
    await delegate.write(key: '_ispectify_test', value: 'test');
    await delegate.delete(key: '_ispectify_test');
  } on PlatformException catch (e) {
    if (e.code == '-34018' || e.message?.contains('-34018') == true) {
      debugPrint('!! Secure Storage: macOS signing error (-34018) detected.');
      debugPrint('!! Falling back to In-Memory storage for this example.');
      delegate = _InMemorySecureStorage();
    } else {
      rethrow;
    }
  }

  // All values are redacted by default (forceRedact: true).
  final storage = ISpectSecureStorage(
    delegate: delegate,
    logger: logger,
  );

  // Store auth tokens
  await storage.write(
    key: 'auth_access_token',
    value: 'eyJhbGciOiJIUzI1NiJ9...',
  );
  await storage.write(
    key: 'auth_refresh_token',
    value: 'dGhpcyBpcyBhIHNlY3JldA==',
  );

  // Store user credentials
  await storage.write(key: 'user_pin', value: '1234');
  await storage.write(key: 'user_biometric_key', value: 'f8f9e1...');

  // Read back — value appears as *** in logs
  await storage.read(key: 'auth_access_token');

  // Check existence
  await storage.containsKey(key: 'user_pin');

  // List all keys (values hidden)
  await storage.readAll();

  // Delete
  await storage.delete(key: 'user_pin');

  // Wipe all
  await storage.deleteAll();
}

/// A minimal in-memory implementation of [FlutterSecureStorage] for the example.
class _InMemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.unmodifiable(_data);

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data.containsKey(key);

  @override
  AndroidOptions get aOptions => const AndroidOptions();
  @override
  IOSOptions get iOptions => const IOSOptions();
  @override
  LinuxOptions get lOptions => const LinuxOptions();
  @override
  AppleOptions get mOptions => const IOSOptions();
  @override
  WebOptions get webOptions => const WebOptions();
  @override
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  Map<String, List<ValueChanged<String?>>> get getListeners => {};

  @override
  Future<bool?> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool>? get onCupertinoProtectedDataAvailabilityChanged => null;

  @override
  void registerListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterAllListeners() {}

  @override
  void unregisterAllListenersForKey({required String key}) {}

  @override
  void unregisterListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}
}
