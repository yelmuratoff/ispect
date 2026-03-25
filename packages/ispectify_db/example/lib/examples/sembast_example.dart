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

void main() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig(enableTransactionMarkers: true);

  final db = await newDatabaseFactoryMemory().openDatabase('example.db');
  final rawStore = intMapStoreFactory.store('users');
  final store = ISpectSembastStore(store: rawStore, logger: logger);

  // Put records
  await store.put(db, 1, {'name': 'Alice', 'role': 'admin'});
  await store.put(db, 2, {'name': 'Bob', 'role': 'user'});

  // Add with auto-key
  final autoKey = await store.add(db, {'name': 'Charlie', 'role': 'user'});
  logger.info('Auto key: $autoKey');

  // Read
  final alice = await store.get(db, 1);
  logger.info('Alice: $alice');

  // Check existence
  final exists = await store.exists(db, 1);
  logger.info('Record 1 exists: $exists');

  // Update
  await store.update(db, 1, {'name': 'Alice', 'role': 'superadmin'});

  // Find all
  final all = await store.find(db);
  logger.info('Found ${all.length} records');

  // Find with filter
  final admins = await store.find(
    db,
    finder: Finder(filter: Filter.equals('role', 'superadmin')),
  );
  logger.info('Admins: ${admins.length}');

  // Count
  final count = await store.count(db);
  logger.info('Total: $count');

  // Transaction
  await store.transaction(db, (txn) async {
    await store.put(txn, 10, {'name': 'Diana', 'role': 'user'});
    await store.put(txn, 11, {'name': 'Eve', 'role': 'user'});
  });

  // Delete record
  await store.deleteRecord(db, 2);

  // Delete with finder
  final deleted = await store.delete(
    db,
    finder: Finder(filter: Filter.equals('role', 'user')),
  );
  logger.info('Deleted $deleted users');

  // Drop store
  await store.drop(db);

  await db.close();
}
