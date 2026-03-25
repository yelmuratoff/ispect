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

Future<void> hiveExample() async {
  final tempDir = Directory.systemTemp.createTempSync('hive_example_');

  try {
    Hive.init(tempDir.path);
    final logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();

    final realBox = await Hive.openBox<String>('settings');
    final box = ISpectHiveBox<String>(delegate: realBox, logger: logger);

    final realUsersBox = await Hive.openBox<Map>('users');
    final usersBox = ISpectHiveBox<Map>(
      delegate: realUsersBox,
      logger: logger,
    );

    // Write
    await box.put('theme', 'dark');
    await box.put('locale', 'en');
    await box.putAll({'fontSize': '14', 'fontFamily': 'Roboto'});

    // Read

    // Auto-key insert
    await box.add('auto-value');

    // Use second box
    await usersBox.put('alice', {'name': 'Alice', 'role': 'admin'});
    usersBox.get('alice');

    // Delete
    await box.delete('fontFamily');

    // Clear
    await box.clear();

    await realBox.close();
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
