/// Example: drift interceptor with code generation (DAOs and typed Queries).
///
/// Ensure you have run:
/// ```bash
/// dart run build_runner build -d
/// ```
/// Run via:
/// ```bash
/// dart run lib/examples/drift_codegen_example.dart
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/drift_interceptor.dart';
import 'package:ispectify_db_example/models/drift_models.dart';

Future<void> driftCodegenExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig(
    slowThreshold: const Duration(milliseconds: 100),
  );

  // 1. Create native memory database and wrap it with ISpectDriftInterceptor
  final executor = NativeDatabase.memory().interceptWith(
    ISpectDriftInterceptor(logger: logger),
  );

  // 2. Initialize the generated AppDatabase with the intercepted executor
  final db = AppDatabase(executor);

  // Insert Category
  await db.into(db.categories).insert(
        CategoriesCompanion.insert(name: 'Work'),
      );

  // Insert Todo
  final todoId = await db.into(db.todos).insert(
        TodosCompanion.insert(
          title: 'Finish Drift Interceptor',
        ),
      );

  // Read
  await db.select(db.todos).get();

  // Read with Where clause
  await (db.select(db.todos)..where((t) => t.done.equals(false))).get();

  // Update
  await (db.update(db.todos)..where((t) => t.id.equals(todoId))).write(
    const TodosCompanion(done: Value(true)),
  );

  // Delete
  await (db.delete(db.todos)..where((t) => t.done.equals(true))).go();

  // Transactions block
  await db.transaction(() async {
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'Personal'),
        );
    await db.into(db.todos).insert(
          TodosCompanion.insert(title: 'Call mom'),
        );
  });

  await db.close();
}
