# ispectify_db example

Ready-to-copy interceptors, runnable examples, and tests for popular
Flutter/Dart storage solutions.

## Quick start

```bash
cd packages/ispectify_db/example
dart pub get

# Run any example
dart run lib/examples/sqflite_example.dart
dart run lib/examples/hive_example.dart

# Run all tests
dart test
```

## Interceptors

Copy the interceptor file into your project, replace the stub types at
the top with real package imports, and you're done.

| File | Package | Category |
|------|---------|----------|
| [sqflite_interceptor.dart](lib/interceptors/sqflite_interceptor.dart) | sqflite | SQL |
| [drift_interceptor.dart](lib/interceptors/drift_interceptor.dart) | drift | SQL (generated) |
| [hive_interceptor.dart](lib/interceptors/hive_interceptor.dart) | hive | Key-Value (typed) |
| [shared_preferences_interceptor.dart](lib/interceptors/shared_preferences_interceptor.dart) | shared_preferences | Key-Value (simple) |
| [flutter_secure_storage_interceptor.dart](lib/interceptors/flutter_secure_storage_interceptor.dart) | flutter_secure_storage | Key-Value (secure) |
| [isar_interceptor.dart](lib/interceptors/isar_interceptor.dart) | isar | NoSQL (collections) |
| [sembast_interceptor.dart](lib/interceptors/sembast_interceptor.dart) | sembast | Document store |
| [firebase_firestore_interceptor.dart](lib/interceptors/firebase_firestore_interceptor.dart) | cloud_firestore | Cloud NoSQL |

## How to use

Each interceptor follows the same pattern:

1. **Create** your real DB/storage instance as usual.
2. **Wrap** it with the `ISpect*` interceptor, passing an `ISpectLogger`.
3. **Use** the wrapper everywhere instead of the original.

```dart
// Before
final db = await openDatabase('app.db');
final rows = await db.rawQuery('SELECT * FROM users');

// After
final db = await openDatabase('app.db');
final traced = ISpectSqfliteDatabase(delegate: db, logger: logger);
final rows = await traced.rawQuery('SELECT * FROM users');
```

All interceptors accept a `source` parameter for custom identification:

```dart
final traced = ISpectSqfliteDatabase(
  delegate: db,
  logger: logger,
  source: 'my-custom-db', // default: 'sqflite'
);
```

## Examples

Each example file is a runnable `main()` that demonstrates realistic
usage with simulated storage (no real dependencies needed):

| File | Storage |
|------|---------|
| [sqflite_example.dart](lib/examples/sqflite_example.dart) | SQL queries, inserts, transactions |
| [drift_example.dart](lib/examples/drift_example.dart) | Select, insert, batch, custom SQL |
| [hive_example.dart](lib/examples/hive_example.dart) | Typed box CRUD, bulk ops |
| [shared_preferences_example.dart](lib/examples/shared_preferences_example.dart) | All typed getters/setters |
| [flutter_secure_storage_example.dart](lib/examples/flutter_secure_storage_example.dart) | Tokens, redacted values |
| [isar_example.dart](lib/examples/isar_example.dart) | Collection CRUD, bulk ops |
| [sembast_example.dart](lib/examples/sembast_example.dart) | Records, queries, transactions |
| [firebase_firestore_example.dart](lib/examples/firebase_firestore_example.dart) | Documents, collections, merge |

## Tests

Every interceptor has a dedicated test file with full coverage:

```bash
dart test                           # all tests
dart test test/interceptors/        # interceptor tests only
```

Each test file uses a fake implementation of the storage interface to
verify that the interceptor:
- Delegates all calls to the underlying storage
- Logs the correct source, operation, keys, and metadata
- Handles errors properly
- Supports custom source names

## Design

- **No hardcoded values**: `source` is configurable via constructor
- **Interface-based**: stub types mirror real package APIs exactly
- **Extensible**: add new operations by implementing the interface
- **Pure Dart**: no Flutter dependency, all examples run with `dart run`
- **Test-friendly**: fakes implement the same interface as real packages
