---
name: new-db-interceptor
description: Scaffold a new database/storage interceptor in ispectify_db example using the shared tracing API. Trigger on "/new-db-interceptor" or when the user asks to add a DB interceptor for a new storage backend.
---

# New DB Interceptor Skill

Create a ready-to-copy interceptor for a database or storage backend in `packages/ispectify_db/example/`.

## When to Use

- User asks to add a DB interceptor for a new storage backend
- User says "/new-db-interceptor"

## Research — MANDATORY First Step

Before writing any code, read the **actual source** of the target library's main class. Use sub-agents only for fact-gathering (method signatures, field list, import paths). Never trust their architectural conclusions.

### What to check (in this order):

1. **Class declaration** — find the main class in `~/.pub-cache/hosted/pub.dev/<package>/lib/`:
   ```bash
   grep -E "\b(sealed|final|base|abstract)?\s*class\s+<ClassName>" <source_file>
   ```
   Record: modifiers, `extends`/`implements`/`with`, generic parameters.

2. **Native hooks** — search for interceptor/observer/middleware classes:
   ```bash
   grep -rE "class\s+\w*(Interceptor|Observer|Middleware|Hook|Listener)" <package_dir>/lib/
   ```
   If found → Native Hook pattern.

3. **Public API** — read the class fully. Record:
   - All public methods with **exact signatures** (return types, generic params, named/positional args)
   - Public fields and their mutability (`final` vs non-final, `late`)
   - Factory vs generative constructors
   - Platform dependencies (`path_provider`, `dart:io`, method channels)

4. **Observation API** — check for `listen`, `watch`, `Stream`, `addListener`, `onChanged` etc. These are passthrough, not traced.

5. **Container/namespace concept** — does it have named stores, boxes, collections, containers? This determines whether to pass `table` parameter.

6. **Test setup** — check how the library handles testing:
   - Does it need platform channel mocks? (e.g., `path_provider` → mock `plugins.flutter.io/path_provider`)
   - Does it have mock/fake constructors? (e.g., `SharedPreferences.setMockInitialValues`)
   - Does it need temp directory for file I/O?
   - Does it need `TestWidgetsFlutterBinding.ensureInitialized()`?

### Research output

After research, you should know:
- Which pattern to use (native hook / drop-in / wrapper) — **verified by reading the class declaration yourself**
- Complete list of methods to trace vs passthrough
- Whether `const` constructor is possible (not possible if delegate has setters you must implement)
- What test setup the library requires

## Decision Tree: Choose the Right Pattern

Evaluate the target library's API **in this order** — use the first match:

### 1. Native Hook (best)

The library provides a built-in interception point (observer, interceptor, middleware).

**Use when:** the library has `QueryInterceptor`, `DatabaseObserver`, `Interceptor`, or similar.

**Pattern:** extend/implement the native hook, call `dbTrace`/`db` inside each callback.

**Example:** `ISpectDriftInterceptor extends QueryInterceptor` — drift routes all SQL through it automatically.

**Rules:**
- Do NOT wrap the database/collection — use the library's own hook mechanism
- Constructor takes `ISpectLogger` + optional `String source`
- No `delegate` getter needed (you're not wrapping anything)

### 2. Drop-in Decorator (preferred when no native hook)

The library exposes an interface or class that can be implemented.

**Use when:** you can write `implements SomeInterface` and the compiler is happy, AND extension methods (if any) resolve correctly on your implementation.

**Pattern:** implement the interface, delegate all methods, trace CRUD operations.

**Examples:**
- `ISpectHiveBox<E> implements Box<E>`
- `ISpectSqfliteDatabase implements Database`
- `ISpectIsarCollection<T> implements IsarCollection<T>`
- `ISpectSharedPreferences implements SharedPreferences`
- `ISpectSecureStorage implements FlutterSecureStorage`
- `ISpectFirestoreCollection<T> implements CollectionReference<T>`
- `ISpectSembastStore<K, V> implements StoreRef<K, V>`
- `ISpectObjectBox<T> implements Box<T>`
- `ISpectRealm implements Realm`
- `ISpectGetStorage implements GetStorage`

### 3. Wrapper (fallback)

The library's types cannot be implemented due to Dart 3 class modifiers (`sealed`, `final`, `base`) or internal runtime casts that break on non-original subtypes.

**Use when:** `implements` fails at compile time OR causes runtime crashes due to internal type checks.

**Pattern:** wrapper class with explicit traced methods + `delegate` getter for escape hatch.

**Rules:**
- Always expose `delegate` getter so users can drop down to the raw API when needed
- Method names should mirror the library's API as closely as possible

### ⚠️ Verification Rule — ALWAYS TRY DROP-IN FIRST

Before choosing wrapper over drop-in, you MUST verify by reading the actual class declaration:

```bash
# Check for Dart 3 modifiers that actually prevent `implements`:
grep -E "\b(sealed|final|base)\s+class\b" <source_file>
```

**These DO prevent `implements`:** `sealed class`, `final class`, `base class`

**These DO NOT prevent `implements`:**
- Factory constructors (e.g., `GetStorage`, `SharedPreferences`)
- Concrete classes without modifiers (e.g., `Box<E>`, `IsarCollection<T>`)
- Singleton patterns
- Classes with `late` or mutable public fields (just delegate them)

**Never trust sub-agent conclusions** about whether `implements` is feasible — always verify the source yourself.

## Structure

All interceptors live in the example project (ready-to-copy, not shipped in the package):

```
packages/ispectify_db/example/
  lib/interceptors/<backend>_interceptor.dart    # Interceptor
  lib/examples/<backend>_example.dart            # Runnable example
  test/interceptors/<backend>_interceptor_test.dart  # Tests
```

## Dependencies

The target library is added to the **example project's** `pubspec.yaml`, not the main package:

```yaml
# packages/ispectify_db/example/pubspec.yaml
dependencies:
  ispectify: ...
  ispectify_db: ...
  <target_library>: ^x.y.z   # ← add here
```

If the interceptor imports types from a **transitive dependency** (e.g., `GetQueue` from `get` package, needed by `get_storage`), add it as a direct dependency too — the analyzer enforces `depend_on_referenced_packages`.

## File Conventions

### Imports

Every interceptor file uses the same two ISpect imports:

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
```

Plus the target library import (use prefix if names clash):

```dart
import 'package:sembast/sembast.dart' as sembast;        // prefix to avoid clashes
import 'package:cloud_firestore/cloud_firestore.dart';   // no prefix if no clashes
```

### Doc Comments

Every interceptor file follows this structure:

```dart
/// Ready-to-copy interceptor for **<library_name>**.
///
/// <Pattern description: implements X / extends Y / wraps Z>.
///
/// ## Setup
/// ```dart
/// <minimal working example>
/// ```
library;

// ignore_for_file directives (if needed)

import ...;

/// <Class-level doc: what it wraps, what's traced, what's passthrough>
final class ISpect<Backend>...
```

### Suppress Directives

| Directive | When |
|-----------|------|
| `// ignore_for_file: subtype_of_sealed_class` | Target class annotated `@sealed` (e.g., Firestore Query, DocumentReference) |
| `// ignore_for_file: invalid_use_of_visible_for_testing_member` | Must implement/access `@visibleForTesting` members (e.g., Isar verify, SecureStorage internals) |

## Implementation Rules

### Constructor Pattern

Every interceptor follows the same constructor shape:

```dart
final class ISpect<Backend>(...) {
  const ISpect<Backend>({
    required <DelegateType> delegate,  // not needed for native hooks
    required ISpectLogger logger,
    String source = defaultSource,
  });

  static const defaultSource = '<backend>';  // lowercase: 'hive', 'sqflite', 'drift'
}
```

- `final class` — no subclassing
- `const` constructor when possible — **NOT possible** when the implemented interface has setters (e.g., GetStorage `queue`, `initStorage`) or non-final public fields you must implement
- Private fields: `_delegate`, `_logger`, `_source`
- Public `delegate` getter (except native hooks)

### Choosing `db()` vs `dbTrace()` vs `dbTraceSync()`

| Scenario | API | Why |
|----------|-----|-----|
| Sync read (in-memory cache) | `_logger.db(...)` | Fire-and-forget, no timing needed |
| Async operation | `_logger.dbTrace(...)` | Auto-timing via Stopwatch, catches errors |
| Sync operation that does I/O | `_logger.dbTraceSync(...)` | Same as dbTrace but synchronous |
| Grouped operations | `_logger.dbTransaction(...)` | Shared transactionId via Zone |

### `dbTrace` Parameters — What to Pass

```dart
_logger.dbTrace(
  source: _source,          // always pass
  operation: 'get',         // always pass — see naming table below
  table: _name,             // collection/store/box name (if applicable)
  key: id.toString(),       // record key/id (if single-record operation)
  statement: sql,           // raw SQL string (SQL databases only)
  args: arguments,          // positional SQL args (SQL databases only)
  namedArgs: values,        // named args / column values (SQL convenience methods)
  meta: {'index': name},    // additional context not covered by other params
  redact: forceRedact,      // force redaction override (secure storage)
  run: () => _db.get(id),   // the actual operation
  projectResult: (v) => {}, // transform result to loggable metadata
);
```

**`table`** — pass when the backend has named stores/collections/boxes/tables:
- Hive: `_box.name`, Isar: `_name`, Sqflite: `table`, Firestore: `_collection.path`, Sembast: `store.name`, GetStorage: `_containerName`, ObjectBox: `_boxName`, Realm: `'$T'` (type name)
- SharedPreferences / SecureStorage: omit (single global store)

**`key`** — pass for single-record operations, omit for bulk/filtered:
- `key: id.toString()`, `key: 'index:$index'`
- For bulk: omit key, use `meta: {'ids': ids.length}` instead

**`meta`** — additional context as `Map<String, dynamic>`:
- `{'box': _box.name}` — Hive box name alongside operation
- `{'index': indexName, 'key': key.toString()}` — Isar index lookups
- `{'entries': entries.length}` — batch size
- `{'merge': true}` — Firestore/Sembast merge mode
- `{'count': values.length}` — number of items in bulk operations
- `{'memoryOnly': true}` — GetStorage writeInMemory (no disk flush)
- `{'ifNull': true}` — GetStorage writeIfNull (conditional write)

### Generics

When the delegate type is generic, the interceptor must be generic with matching constraints:

```dart
// Delegate is Box<E> → interceptor is ISpectHiveBox<E>
final class ISpectHiveBox<E> implements Box<E> { ... }

// Delegate is IsarCollection<T> → interceptor is ISpectIsarCollection<T>
final class ISpectIsarCollection<T> implements IsarCollection<T> { ... }

// Delegate has bounded generics → preserve bounds
final class ISpectSembastStore<K extends RecordKeyBase?, V extends RecordValueBase?>
    implements StoreRef<K, V> { ... }

// Delegate has Object? bound (Firestore) → preserve it
final class ISpectFirestoreCollection<T extends Object?>
    implements CollectionReference<T> { ... }
```

### Multi-Class Interceptors

Some backends require multiple related classes in one file:

**Firestore** — Collection + Document:
```
ISpectFirestoreCollection<T> implements CollectionReference<T>
ISpectFirestoreDocument<T> implements DocumentReference<T>
```
`doc()` on collection returns `ISpectFirestoreDocument`, `parent` on document returns `ISpectFirestoreCollection`.

**Sembast** — Store + Record + Extension:
```
ISpectSembastStore<K, V> implements StoreRef<K, V>
ISpectSembastRecord<K, V> implements RecordRef<K, V>
extension ISpectSembastStoreExtension on StoreRef  → .traced(logger)
```
`record()` on store returns `ISpectSembastRecord` (covariant return type).

**Rule:** if the backend has a parent→child navigation pattern (collection→document, store→record), both levels need traced wrappers so tracing isn't lost during navigation.

### Operation Naming

Use consistent operation names across all interceptors:

| Operation | Category | When |
|-----------|----------|------|
| `get` | `db-query` | Single record read by key/id |
| `query` / `select` / `find` | `db-query` | Multi-record read, SQL SELECT |
| `lookup` | `db-query` | Existence check (containsKey, exists) |
| `list` / `count` | `db-query` | Enumerate keys or count records |
| `read` | `db-query` | Generic read (SharedPreferences style) |
| `write` / `put` / `set` | `db-result` | Insert or update (upsert) |
| `insert` / `add` | `db-result` | Insert only (auto-key) |
| `update` | `db-result` | Update only |
| `delete` | `db-result` | Single or filtered delete |
| `clear` / `drop` | `db-result` | Bulk delete / drop store |
| `execute` / `batch` | `db-result` | Raw SQL or batch operations |
| `importJson` | `db-result` | Bulk import |

### `projectResult` — What to Return

Project meaningful metadata, never raw objects:

```dart
// Counts
projectResult: (rows) => {'rows': rows.length}
projectResult: (n) => {'affected': n}
projectResult: (n) => {'deleted': n}
projectResult: (n) => {'count': n}

// Identity
projectResult: (id) => {'id': id}
projectResult: (id) => {'lastInsertId': id}
projectResult: (key) => {'autoKey': key}
projectResult: (ref) => {'docId': ref.id}

// Existence
projectResult: (snap) => {'exists': snap.exists}
projectResult: (val) => {'exists': val}
projectResult: (val) => val != null ? '1 object' : 'null'

// Cache
cacheHit: result != null  // for sync reads via db()
```

### Tracing Scope — What to Trace vs Passthrough

**Trace (wrap in dbTrace/db):**
- All CRUD: get, put, insert, update, delete, clear
- Aggregations: count, getSize
- Queries: find, findFirst, select
- Import/export: importJson, importJsonRaw

**Passthrough (delegate directly):**
- Query builders: where, orderBy, limit, filter — tracing these is noise
- Streams/watchers: snapshots, watch, onSnapshot — continuous, not point-in-time
- Callback listeners: listen, listenKey, addListener — user-facing observation hooks
- Lifecycle: open, close, compact, flush — admin, not data operations
- Schema/metadata: schema, name, path, isOpen
- Configuration: options getters, platform-specific settings
- `keys`/`values` property getters on in-memory cache (Hive `box.keys`, `box.values`) — but if it's an explicit method call that enumerates stored data (GetStorage `getKeys()`, `getValues()`), **trace it** as `list` operation

### Navigation Must Preserve Tracing

When a method returns a related object that the user will interact with, return a **traced wrapper** — not the raw delegate:

```dart
// DO: tracing preserved across navigation
@override
ISpectFirestoreDocument<T> doc([String? path]) => ISpectFirestoreDocument(
      delegate: _collection.doc(path),
      logger: _logger,
      source: _source,
    );

@override
CollectionReference<T> get parent => ISpectFirestoreCollection(
      delegate: _doc.parent,
      logger: _logger,
      source: _source,
    );

// DON'T: tracing lost
@override
DocumentReference<T> doc([String? path]) => _collection.doc(path);
```

Same applies to `withConverter` — return a new traced wrapper around the converted delegate.

### Extension Shadowing (Sembast-style)

When a library's API is extension-based, instance methods shadow extensions:

```dart
// Sembast extensions define: StoreRef.find(db)
// Our class defines:        ISpectSembastStore.find(db)  ← wins

final class ISpectSembastStore<K, V> implements StoreRef<K, V> {
  // Instance method — shadows the Sembast extension
  Future<List<RecordSnapshot<K, V>>> find(DatabaseClient db, {Finder? finder}) =>
      _logger.dbTrace(...);
}
```

**Rules for extension shadowing:**
- Method signature must exactly match the extension method
- Return covariant types from navigation methods (e.g., `record()` returns `ISpectSembastRecord`)
- Passthrough methods that internally cast `this` to a concrete type (they'd crash on our implementation)
- Add a convenience extension: `.traced(logger)` on the base type

### Redaction

- **Secure storage:** `forceRedact: true` by default, `projectResult` returns `'***'` not actual values
- **All others:** delegate to `ISpectDbConfig.redact` — don't make per-interceptor redaction decisions
- Never log raw values of sensitive data (tokens, passwords, PII)

### Equality

If the wrapped type has value equality semantics, preserve them:

```dart
// Sembast: StoreRef equality is name-based
@override
bool operator ==(Object other) {
  if (other is StoreRef) return other.name == name;
  return false;
}

@override
int get hashCode => name.hashCode;
```

### DRY Helpers

When multiple methods share the same logging pattern, extract a private helper:

```dart
// SharedPreferences: all sync reads share the same logging shape
T? _logRead<T>(String key, T? result) {
  _logger.db(
    source: _source,
    operation: 'read',
    key: key,
    success: true,
    cacheHit: result != null,
  );
  return result;
}

// Usage:
@override
String? getString(String key) => _logRead(key, _prefs.getString(key));

@override
int? getInt(String key) => _logRead(key, _prefs.getInt(key));
```

Don't over-abstract — only extract when 3+ methods share the exact same shape.

### `@sealed` / `@immutable` Suppressions

If the target class is annotated `@sealed` but is abstract (like Firestore's `Query`, `DocumentReference`):

```dart
// ignore_for_file: subtype_of_sealed_class
```

This is acceptable — `@sealed` is a lint hint, not a language restriction. The decorator pattern is the correct solution here.

## Example File

The example must be runnable and demonstrate all traced operations:

```dart
Future<void> <backend>Example() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();
  // Setup: open DB, create interceptor
  // Writes: insert, update, upsert
  // Reads: get, find, count, exists
  // Deletes: single, bulk, clear
  // Transaction (if supported)
  // Cleanup: close
}
```

## Test File

### Test Setup — Platform Dependencies

Many storage libraries depend on platform channels or file I/O that don't work in `flutter test` without mocks. Common patterns:

| Library needs | Test setup |
|---------------|------------|
| `path_provider` | Mock method channel: `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), ...)` |
| `SharedPreferences` | `SharedPreferences.setMockInitialValues({})` |
| File I/O | Create temp dir: `Directory.systemTemp.createTemp(...)`, clean up in `tearDown` |
| Flutter binding | `TestWidgetsFlutterBinding.ensureInitialized()` in `setUpAll` |
| Singleton caches | Use unique container/instance names per test to avoid cross-test pollution (e.g., `'test_${tempDir.hashCode}'`) |
| Background flushes | Add small delay in `tearDown` before clearing mocks: `await Future.delayed(Duration(milliseconds: 50))` |

**Important:** Some libraries call platform APIs even when a custom path is provided (e.g., GetStorage always calls `getApplicationDocumentsDirectory()` internally). Always mock platform channels regardless of constructor arguments.

### Test Scenarios

Cover these scenarios:

| Group | Tests |
|-------|-------|
| Write ops | put/insert logs correct operation, table, key |
| Read ops | get/find logs correct operation, returns real data |
| Delete ops | delete/clear logs, data actually removed |
| Aggregation | count logs correct value |
| Transaction | inner calls carry transactionId |
| Custom source | `source: 'custom'` appears in logs |
| Drop-in | type assignable to interface (`StoreRef x = traced;`) |
| Equality | if applicable: `traced == rawRef` |

Use `logger.history` to assert on logged entries.

## Checklist

Before marking complete:

**Architecture:**
- [ ] Read actual class declaration — verified no `sealed`/`final`/`base` modifiers before choosing pattern
- [ ] Pattern chosen correctly (native hook > drop-in > wrapper)
- [ ] Multi-class interceptor if backend has parent→child navigation
- [ ] Generic type parameters match delegate's constraints

**Code quality:**
- [ ] `dart analyze` / `flutter analyze` — zero issues
- [ ] All tests pass
- [ ] `final class`, `const` constructor where possible
- [ ] `delegate` getter exposed (unless native hook)
- [ ] Private fields: `_delegate`/`_db`/etc., `_logger`, `_source`
- [ ] `static const defaultSource` — lowercase backend name
- [ ] DRY helpers extracted for 3+ methods with same logging shape

**Logging correctness:**
- [ ] Operation names follow the naming table
- [ ] `projectResult` returns metadata, not raw objects
- [ ] `table` passed when backend has named stores/collections
- [ ] `key` passed for single-record ops, `meta` for bulk context
- [ ] `statement`/`args` passed for SQL interceptors
- [ ] Correct API chosen: `db()` for sync cache reads, `dbTrace()` for async, `dbTraceSync()` for sync I/O

**Tracing integrity:**
- [ ] Navigation methods return traced wrappers (not raw delegates)
- [ ] `withConverter` returns new traced wrapper
- [ ] Equality preserved if base type has value equality
- [ ] Extension shadowing: signatures match exactly, passthrough for `this`-casting methods

**Security:**
- [ ] Secure data redacted by default (if applicable)
- [ ] No raw sensitive values in `projectResult`

**File conventions:**
- [ ] `library;` directive, doc comments with Setup example
- [ ] `ignore_for_file` directives where needed (`subtype_of_sealed_class`, `invalid_use_of_visible_for_testing_member`)
- [ ] Imports: `ispectify` + `ispectify_db` + target library
- [ ] Target library added to example `pubspec.yaml` (+ transitive deps if imported directly)

**Deliverables:**
- [ ] Interceptor file: `lib/interceptors/<backend>_interceptor.dart`
- [ ] Example file: `lib/examples/<backend>_example.dart`
- [ ] Test file: `test/interceptors/<backend>_interceptor_test.dart`
- [ ] `main.dart` updated: import added, entry added to `_examples` map
