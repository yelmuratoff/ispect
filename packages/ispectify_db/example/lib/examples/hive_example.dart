/// Example: Hive interceptor with a real Hive box.
///
/// ```bash
/// dart run lib/examples/hive_example.dart
/// ```
library;

import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/hive_interceptor.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('hive_example_');

  try {
    Hive.init(tempDir.path);
    final logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();

    final realBox = await Hive.openBox<String>('settings');
    final box = ISpectHiveBox<String>(delegate: realBox, logger: logger);

    // Write
    await box.put('theme', 'dark');
    await box.put('locale', 'en');
    await box.putAll({'fontSize': '14', 'fontFamily': 'Roboto'});

    // Read
    logger
      ..info('Theme: ${box.get('theme')}')
      ..info('Has locale: ${box.containsKey('locale')}');

    // Auto-key insert
    final autoKey = await box.add('auto-value');
    logger
      ..info('Auto key: $autoKey')
      ..info('Keys: ${box.keys.toList()}')
      ..info('Count: ${box.length}');

    // Delete
    await box.delete('fontFamily');

    // Clear
    final cleared = await box.clear();
    logger.info('Cleared $cleared entries');

    await realBox.close();
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
