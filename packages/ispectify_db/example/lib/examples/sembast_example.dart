/// Example: sembast interceptor with a real in-memory database.
///
/// ```bash
/// dart run lib/examples/sembast_example.dart
/// ```
library;

import 'package:ispectify/ispectify.dart' hide Filter;
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/sembast_interceptor.dart';
import 'package:sembast/sembast_memory.dart';

Future<void> sembastExample() async {
  final logger = ISpectLogger();
  const dbConfig = ISpectDbConfig(enableTransactionMarkers: true);

  final db = await newDatabaseFactoryMemory().openDatabase('example.db');

  // Convenience extension: .traced(logger)
  final store =
      intMapStoreFactory.store('users').traced(logger, config: dbConfig);
  final settingsStore =
      stringMapStoreFactory.store('settings').traced(logger, config: dbConfig);

  // Record-level operations via store.record(key)
  await store.record(1).put(db, {'name': 'Alice', 'role': 'admin'});
  await store.record(2).put(db, {'name': 'Bob', 'role': 'user'});

  // Add with auto-key (store-level)
  await store.add(db, {'name': 'Charlie', 'role': 'user'});

  // Put in second store
  await settingsStore.record('theme').put(db, {'darkMode': true});
  await settingsStore.record('language').put(db, {'code': 'en'});

  // Record read
  await store.record(1).get(db);

  // Check existence
  await store.record(1).exists(db);

  // Record update
  await store.record(1).update(db, {'name': 'Alice', 'role': 'superadmin'});

  // Find all
  await store.find(db);

  // Find with filter
  await store.find(
    db,
    finder: Finder(filter: Filter.equals('role', 'superadmin')),
  );

  // Count
  await store.count(db);

  // Transaction
  await store.transaction(db, (txn) async {
    await store.record(10).put(txn, {'name': 'Diana', 'role': 'user'});
    await store.record(11).put(txn, {'name': 'Eve', 'role': 'user'});
  });

  // Delete record
  await store.record(2).delete(db);

  // Delete with finder (store-level)
  await store.delete(
    db,
    finder: Finder(filter: Filter.equals('role', 'user')),
  );

  // Drop store
  await store.drop(db);

  await db.close();
}
