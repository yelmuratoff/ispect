# ispectify_db example

Ready-to-copy interceptors, runnable examples, and tests for popular
Flutter/Dart storage solutions.

## Quick start

This is a Flutter project that depends on the real storage packages
(`sqflite_common`, `drift`, `hive_ce`, `sembast`, `isar_community`,
`objectbox`, `realm`, `cloud_firestore`, `shared_preferences`,
`flutter_secure_storage`, `get_storage`). Dependency resolution currently
needs the CI-pinned Flutter 3.32.x; newer SDKs conflict with `realm`'s
`analyzer` constraint.

```bash
cd packages/ispectify_db/example
flutter pub get
dart run build_runner build -d

# Launch the example app and run any example from the list
flutter run -d macos --dart-define=ISPECT_ENABLED=true

# Run all tests
flutter test --dart-define=ISPECT_ENABLED=true
```

Without `ISPECT_ENABLED=true` the logger is inert and the tests that assert on
log history fail.

## Interceptors

Copy the interceptor file into your project, add the storage package it
imports, and you're done. Each interceptor implements (or, for drift,
extends) the real package type, so it is a drop-in replacement.

| File | Package | Category |
|------|---------|----------|
| [sqflite_interceptor.dart](lib/interceptors/sqflite_interceptor.dart) | sqflite / sqflite_common | SQL |
| [drift_interceptor.dart](lib/interceptors/drift_interceptor.dart) | drift | SQL (query interceptor) |
| [hive_interceptor.dart](lib/interceptors/hive_interceptor.dart) | hive_ce | Key-Value (typed) |
| [shared_preferences_interceptor.dart](lib/interceptors/shared_preferences_interceptor.dart) | shared_preferences | Key-Value (simple) |
| [flutter_secure_storage_interceptor.dart](lib/interceptors/flutter_secure_storage_interceptor.dart) | flutter_secure_storage | Key-Value (secure) |
| [get_storage_interceptor.dart](lib/interceptors/get_storage_interceptor.dart) | get_storage | Key-Value |
| [isar_interceptor.dart](lib/interceptors/isar_interceptor.dart) | isar_community | NoSQL (collections) |
| [objectbox_interceptor.dart](lib/interceptors/objectbox_interceptor.dart) | objectbox | NoSQL (boxes) |
| [realm_interceptor.dart](lib/interceptors/realm_interceptor.dart) | realm | Object database |
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

Each example file exposes an async function that runs realistic operations
against the real package, using in-memory databases, temporary directories,
or `fake_cloud_firestore` where possible. [`lib/main.dart`](lib/main.dart)
lists them all in a Flutter app with a "Run All Examples" button:

| File | Storage |
|------|---------|
| [sqflite_example.dart](lib/examples/sqflite_example.dart) | SQL queries, inserts, transactions |
| [drift_example.dart](lib/examples/drift_example.dart) | Select, insert, batch, custom SQL |
| [drift_codegen_example.dart](lib/examples/drift_codegen_example.dart) | Generated database and typed queries |
| [hive_example.dart](lib/examples/hive_example.dart) | Typed box CRUD, bulk ops |
| [shared_preferences_example.dart](lib/examples/shared_preferences_example.dart) | All typed getters/setters |
| [flutter_secure_storage_example.dart](lib/examples/flutter_secure_storage_example.dart) | Tokens, redacted values |
| [get_storage_example.dart](lib/examples/get_storage_example.dart) | Writes, reads, key listing, deletes |
| [isar_example.dart](lib/examples/isar_example.dart) | Collection CRUD, bulk ops |
| [objectbox_example.dart](lib/examples/objectbox_example.dart) | Sync and async puts/gets, counts |
| [realm_example.dart](lib/examples/realm_example.dart) | Write transactions, reads, updates, deletes |
| [sembast_example.dart](lib/examples/sembast_example.dart) | Records, queries, transactions |
| [firebase_firestore_example.dart](lib/examples/firebase_firestore_example.dart) | Documents, collections, merge |

The drift, Isar, and ObjectBox models need generated code that is not
committed; rerun `dart run build_runner build -d` after changing a model.

## Tests

Every interceptor has a dedicated test file:

```bash
flutter test --dart-define=ISPECT_ENABLED=true                     # all tests
flutter test --dart-define=ISPECT_ENABLED=true test/interceptors/  # interceptor tests only
```

Tests run against the real packages: in-memory databases, temporary
directories, `fake_cloud_firestore`, and mocked platform channels for the
Flutter plugins. They verify that the interceptor:
- Delegates all calls to the underlying storage
- Logs the correct source, operation, keys, and metadata
- Handles errors properly
- Supports custom source names

## Design

- **No hardcoded values**: `source` is configurable via constructor
- **Drop-in**: interceptors implement the real package interfaces
- **Extensible**: add new operations by delegating and tracing them the same way
- **Real drivers**: examples and tests exercise the actual storage packages
