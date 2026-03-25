/// Example: FlutterSecureStorage interceptor with real package.
///
/// Requires Flutter context. Run via `flutter test` or in a Flutter app.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/flutter_secure_storage_interceptor.dart';

Future<void> secureStorageExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  // All values are redacted by default (forceRedact: true).
  final storage = ISpectSecureStorage(
    delegate: const FlutterSecureStorage(),
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
