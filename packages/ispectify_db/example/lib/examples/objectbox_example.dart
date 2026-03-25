/// Example: ObjectBox interceptor with a real ObjectBox store.
///
/// Requires ObjectBox native library and code generation.
/// ```bash
/// cd packages/ispectify_db/example
/// dart run build_runner build
/// dart run lib/examples/objectbox_example.dart
/// ```
library;

import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/objectbox_interceptor.dart';
import 'package:ispectify_db_example/models/objectbox_task.dart';
import 'package:ispectify_db_example/objectbox.g.dart';

Future<void> objectboxExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  final tempDir = Directory.systemTemp.createTempSync('objectbox_example_');

  try {
    final store = await openStore(directory: tempDir.path);
    final tasks = ISpectObjectBox<ObjectBoxTask>(
      delegate: store.box<ObjectBoxTask>(),
      logger: logger,
      boxName: 'Task',
    );

    // Sync writes
    final id1 = tasks.put(ObjectBoxTask()..text = 'Buy milk');
    tasks.put(
      ObjectBoxTask()
        ..text = 'Write tests'
        ..done = true,
    );

    // Bulk write
    tasks.putMany([
      ObjectBoxTask()..text = 'Review PR',
      ObjectBoxTask()..text = 'Deploy',
    ]);

    // Async write
    await tasks.putAsync(ObjectBoxTask()..text = 'Async task');

    // Sync reads
    tasks.get(id1);
    tasks.getMany([1, 2, 999]);
    tasks.getAll();

    // Async reads
    await tasks.getAsync(id1);
    await tasks.getAllAsync();

    // Aggregations
    tasks.count();
    tasks.isEmpty();
    tasks.contains(id1);
    tasks.containsMany([1, 2]);

    // Sync deletes
    tasks.remove(id1);

    // Async delete
    await tasks.removeManyAsync([2, 3]);

    // Clear
    tasks.removeAll();

    store.close();
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
