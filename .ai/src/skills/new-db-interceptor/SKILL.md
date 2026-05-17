---
name: new-db-interceptor
description: Scaffold a new database or storage interceptor in `packages/ispectify_db/example` using the shared ISpect DB tracing API. Use when adding support for a new backend such as Hive, SharedPreferences, Drift, Isar, Realm, Sembast, ObjectBox, Firestore, secure storage, or another storage driver.
---

# New DB Interceptor

Create a ready-to-copy database/storage interceptor example for `ispectify_db`.

## Research First

1. Read the target library's actual source in `.pub-cache` or package docs installed locally.
2. Record the main class declaration: modifiers, `extends`, `implements`, mixins, generic bounds, constructors, and public methods.
3. Search for native hooks first: `Interceptor`, `Observer`, `Middleware`, `Hook`, `Listener`, `QueryInterceptor`.
4. Identify methods to trace: CRUD, query, count, import/export, batch, transaction-like operations.
5. Identify passthrough methods: query builders, streams/watchers, listeners, lifecycle/admin, schema/config getters.
6. Check test setup requirements: platform channel mocks, temp directories, fake constructors, Flutter binding, singleton cleanup.

## Pattern Decision

Use the first viable pattern:

1. Native hook: extend or implement the library's observer/interceptor when it exists, as Drift does with `QueryInterceptor`.
2. Drop-in decorator: implement the library interface/class and delegate all methods when Dart modifiers allow it.
3. Wrapper fallback: expose traced methods plus a `delegate` getter when `sealed`, `final`, `base`, or runtime casts prevent drop-in implementation.

Before choosing wrapper, verify the class declaration yourself. Factory constructors, singleton patterns, and mutable fields do not by themselves prevent `implements`.

## File Layout

Place all files in the example app:

```
packages/ispectify_db/example/
  lib/interceptors/<backend>_interceptor.dart
  lib/examples/<backend>_example.dart
  test/interceptors/<backend>_interceptor_test.dart
```

Add the target dependency to `packages/ispectify_db/example/pubspec.yaml`, not to the publishable `ispectify_db` package.

## Implementation Rules

- Import `package:ispectify/ispectify.dart` and `package:ispectify_db/ispectify_db.dart`.
- Use `final class` for interceptor classes.
- Prefer a constructor shape with `delegate`, `logger`, and `source`; expose `delegate` except for native hooks.
- Use `static const defaultSource = '<backend>'` with a lowercase source name.
- Use `_logger.db(...)` for sync in-memory reads where timing is not useful.
- Use `_logger.dbTrace(...)` for async operations.
- Use `_logger.dbTraceSync(...)` for sync operations that do meaningful work.
- Use `_logger.dbTransaction(...)` or transaction IDs when grouping related operations.
- Pass `source`, `operation`, and the most specific of `table`, `target`, or `key`.
- Pass SQL `statement`, positional `args`, and `namedArgs` only when the backend has SQL-like data.
- Return metadata from `projectResult`, not raw stored objects.
- Preserve navigation tracing: methods like `collection.doc()`, `store.record()`, or `withConverter()` should return traced wrappers when users continue operating through the returned object.

## Operation Names

- Reads: `get`, `query`, `select`, `find`, `lookup`, `list`, `count`, `read`.
- Writes: `write`, `put`, `set`, `insert`, `add`, `update`.
- Deletes/admin data ops: `delete`, `clear`, `drop`.
- Raw or grouped work: `execute`, `batch`, `importJson`.

## Projection Defaults

- Counts: `{'rows': rows.length}`, `{'affected': n}`, `{'deleted': n}`, `{'count': n}`.
- Identity: `{'id': id}`, `{'lastInsertId': id}`, `{'docId': ref.id}`.
- Existence: `{'exists': value != null}` or `cacheHit: value != null`.
- Secure values: return `'***'` or metadata only.

## Tests

1. Assert the traced wrapper is assignable to the intended interface when using drop-in decorator.
2. Test write, read, delete, count, and error paths.
3. Assert log entry `source`, `operation`, `target/table/key`, `duration`, and DB-specific `meta`.
4. Assert transaction IDs are carried through nested operations when supported.
5. Assert sensitive values are redacted or projected away.
6. Use temp directories and platform channel mocks when the backend requires them.

## Gotchas

- Some libraries call platform APIs even when given a custom path; mock channels anyway in Flutter tests.
- If a backend has parent-child navigation, both levels usually need wrappers or tracing is lost.
- `@sealed` annotations are lint hints, but language-level `sealed class`, `final class`, and `base class` affect implementation choices.
- Extension-based APIs need exact method signatures if instance methods are meant to shadow extension methods.
- Secure storage should force redaction by default; do not rely on callers to remember it.
