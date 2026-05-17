/// Example: Isar Community Edition interceptor with real database.
///
/// Requires native Isar core (auto-downloaded on first run).
/// ```bash
/// dart run lib/examples/isar_example.dart
/// ```
library;

import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db_example/interceptors/isar_interceptor.dart';
import 'package:ispectify_db_example/models/isar_post.dart';
import 'package:ispectify_db_example/models/isar_user.dart';

Future<void> isarExample() async {
  await Isar.initializeIsarCore(download: true);

  final logger = ISpectLogger();

  final tempDir = Directory.systemTemp.createTempSync('isar_example_');

  try {
    final isar = await Isar.open(
      [IsarUserSchema, IsarPostSchema],
      directory: tempDir.path,
    );
    final users = ISpectIsarCollection<IsarUser>(
      delegate: isar.isarUsers,
      logger: logger,
      collectionName: 'users',
    );
    final posts = ISpectIsarCollection<IsarPost>(
      delegate: isar.isarPosts,
      logger: logger,
      collectionName: 'posts',
    );

    // Insert
    await isar.writeTxn(() async {
      await users.put(IsarUser()..name = 'Alice');
      await users.put(
        IsarUser()
          ..name = 'Bob'
          ..email = 'bob@example.com',
      );
      await posts.put(
        IsarPost()
          ..title = 'Hello World'
          ..content = 'First post',
      );
    });

    // Bulk insert
    await isar.writeTxn(() async {
      await users.putAll([
        IsarUser()..name = 'Charlie',
        IsarUser()..name = 'Diana',
      ]);
    });

    // Read
    await users.get(1);

    // Read multiple
    await users.getAll([1, 2, 999]);

    // Count
    await users.count();

    // Delete
    await isar.writeTxn(() async {
      await users.delete(2);
    });

    // Clear
    await isar.writeTxn(users.clear);

    await isar.close();
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
