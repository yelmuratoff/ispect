/// Example: GetStorage interceptor with real package.
///
/// Requires Flutter context for path resolution:
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// await getStorageExample();
/// ```
library;

import 'package:get_storage/get_storage.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/get_storage_interceptor.dart';

Future<void> getStorageExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  // Initialize and wrap
  await GetStorage.init('ispect_example');
  final box = GetStorage('ispect_example');
  final traced = ISpectGetStorage(
    delegate: box,
    logger: logger,
    containerName: 'ispect_example',
  );

  // --- Writes ---
  await traced.write('user_theme', 'dark');
  await traced.write('user_locale', 'en');
  await traced.write('launch_count', 42);
  await traced.write('tags', ['flutter', 'dart', 'ispect']);

  // Write only if absent
  await traced.writeIfNull('user_theme', 'light'); // skipped — already exists

  // Memory-only write (no disk flush)
  traced.writeInMemory('temp_flag', true);

  // --- Reads ---
  final theme = traced.read<String>('user_theme');
  logger.info('Theme: $theme');

  final count = traced.read<int>('launch_count');
  logger.info('Launch count: $count');

  // Existence check
  final hasTheme = traced.hasData('user_theme');
  logger.info('Has theme: $hasTheme');

  // List keys and values
  final keys = traced.getKeys();
  logger.info('Keys: $keys');

  final values = traced.getValues();
  logger.info('Values count: ${values.length}');

  // --- Deletes ---
  await traced.remove('temp_flag');
  await traced.erase();
}
