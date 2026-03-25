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

  // Store sensitive data
  await storage.write(key: 'access_token', value: 'eyJhbGciOiJIUzI1NiJ9...');
  await storage.write(
    key: 'refresh_token',
    value: 'dGhpcyBpcyBhIHNlY3JldA==',
  );
  await storage.write(key: 'pin', value: '1234');

  // Read back — value appears as *** in logs
  final token = await storage.read(key: 'access_token');
  logger.info('Token exists: ${token != null}');

  // Check existence
  final hasPin = await storage.containsKey(key: 'pin');
  logger.info('Has PIN: $hasPin');

  // List all keys (values hidden)
  final all = await storage.readAll();
  logger.info('Stored ${all.length} secrets');

  // Delete
  await storage.delete(key: 'pin');

  // Wipe all
  await storage.deleteAll();
}
