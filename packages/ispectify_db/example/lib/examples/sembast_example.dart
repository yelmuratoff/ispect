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
  ISpectDbCore.config = ISpectDbConfig(enableTransactionMarkers: true);

  final db = await newDatabaseFactoryMemory().openDatabase('example.db');
  final rawStore = intMapStoreFactory.store('users');
  final store = ISpectSembastStore(store: rawStore, logger: logger);

  final rawSettingsStore = stringMapStoreFactory.store('settings');
  final settingsStore =
      ISpectSembastStore(store: rawSettingsStore, logger: logger);

  // Put records
  await store.put(db, 1, {'name': 'Alice', 'role': 'admin'});
  await store.put(db, 2, {'name': 'Bob', 'role': 'user'});

  // Add with auto-key
  await store.add(db, {'name': 'Charlie', 'role': 'user'});

  // Put in second store
  await settingsStore.put(db, 'theme', {'darkMode': true});
  await settingsStore.put(db, 'language', {'code': 'en'});

  // Read
  await store.get(db, 1);

  // Check existence
  await store.exists(db, 1);

  // Update
  await store.update(db, 1, {'name': 'Alice', 'role': 'superadmin'});

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
    await store.put(txn, 10, {'name': 'Diana', 'role': 'user'});
    await store.put(txn, 11, {'name': 'Eve', 'role': 'user'});
  });

  // Delete record
  await store.deleteRecord(db, 2);

  // Delete with finder
  await store.delete(
    db,
    finder: Finder(filter: Filter.equals('role', 'user')),
  );

  // Drop store
  await store.drop(db);

  await db.close();
}
