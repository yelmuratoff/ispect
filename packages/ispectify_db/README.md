# ispectify_db

Passive database logging utilities for the ISpect toolkit. Keep your DB calls as-is and simply log intents, timings, and results. Works with SQL and key-value stores (sqflite, drift, hive, shared_preferences, etc.) without importing them in this package.

- No adapters required (yet) — call one or two methods.
- Minimal API, maximum flexibility.
- Redaction, sampling, truncation, SQL digest, slow query mark, transaction markers.

## Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify: ^4.3.6
  ispectify_db:
    path: ../ispectify_db # or from pub when published
```

Then import:

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
```

## Quick Start

Configure (optional):

```dart
ISpectDbCore.config = const ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  attachStackOnError: true,
  enableTransactionMarkers: false,
  slowQueryThreshold: Duration(milliseconds: 400),
);
```

Log a simple event:

```dart
ISpect.logger.db(
  source: 'SharedPreferences',
  operation: 'write',
  target: 'language',
  value: 'eu',
);
```

Wrap an async DB call to capture duration + success/error:

```dart
final rows = await ISpect.logger.dbTrace<List<Map<String, Object?}}>(
  source: 'sqflite',
  operation: 'query',
  statement: 'SELECT * FROM users WHERE id = ?',
  args: [userId],
  table: 'users',
  run: () => db.rawQuery('SELECT * FROM users WHERE id = ?', [userId]),
  projectResult: (rows) => {'rows': rows.length},
);
```

Errors automatically include stack traces when `attachStackOnError: true`:

```dart
try {
  await ISpect.logger.dbTrace<void>(
    source: 'sqflite',
    operation: 'insert',
    statement: 'INSERT INTO users (name) VALUES (?)',
    args: ['Alice'],
    run: () => db.rawInsert('INSERT INTO users (name) VALUES (?)', ['Alice']),
  );
} catch (e, s) {
  // The original stack trace `s` is captured and logged by dbTrace.
}
```

Manual start/end:

```dart
final t = ISpect.logger.dbStart(
  source: 'hive',
  operation: 'get',
  key: 'session',
);
try {
  final value = await box.get('session');
  ISpect.logger.dbEnd(t, value: value, success: true);
} catch (e) {
  ISpect.logger.dbEnd(t, error: e, success: false);
  rethrow;
}
```

Transaction markers (with shared transactionId via Zone):

```dart
await ISpect.logger.dbTransaction(
  source: 'sqflite',
  logMarkers: true,
  run: () async {
    await ISpect.logger.dbTrace(
      source: 'sqflite',
      operation: 'update',
      statement: 'UPDATE users SET name=? WHERE id=?',
      args: ['Bob', 1],
      run: () => db.rawUpdate('UPDATE users SET name=? WHERE id=?', ['Bob', 1]),
    );
  },
);
```

## API Reference

- `configureISpectDb(ISpectDbConfig config)` — set global behavior: sampling, redaction, truncation, slow threshold, transaction markers.
- `ISpectify.db(...)` — emit a single DB event.
- `ISpectify.dbTrace<T>(...)` — wrap a `Future<T>` and emit on completion (success or error) with duration.
- `ISpectify.dbStart(...)` / `ISpectify.dbEnd(...)` — manual span around arbitrary code.
- `ISpectify.dbTransaction(...)` — run a closure with a shared `transactionId` and optional begin/commit/rollback markers.

### Common fields

- `source`: driver or component name, e.g. `sqflite` | `drift` | `hive` | `shared_prefs` | `custom`.
- `operation`: `query` | `insert` | `update` | `delete` | `get` | `put` | `remove` | `write` | `read` | `transaction-*` | `custom`.
- `statement`: SQL string (if any). A truncated version and a normalized `statementDigest` are stored.
- `target` / `table` / `key`: pick what applies.
- `args` / `namedArgs`: parameters for queries.
- `value` or `projectResult`: logged value (redacted/truncated). Prefer `projectResult` for large results.
- `meta`: free-form context.

### Redaction & Truncation

- Redaction replaces values for keys in `redactKeys` (case-insensitive) in `args`, `namedArgs`, `meta`, and `value` maps.
- Truncation applies to long `statement` strings and leaf string values inside `args`, `namedArgs`, and `value`. Structure is preserved.
- Limits are controlled by `maxStatementLength`, `maxArgsLength`, and `maxValueLength`.

### Sampling

- Per-call sampling: pass `sample: 0.1` to log about 10% of calls.
- Global sampling: via `ISpectDbConfig.sampleRate`.

### Slow queries

- If `slowQueryThreshold` is set, completed events will include `slow: true` when duration exceeds the threshold.

## Structured Event

The underlying `ISpectifyData` uses keys already recognized by ISpect UI:
- `db-query`: query/read operations
- `db-result`: non-query successful operations
- `db-error`: failed operations

`additionalData` contains:
```
{
  source, operation, statement, statementDigest,
  target, table, key,
  args, namedArgs,
  durationMs, slow, success, affected, items,
  value, meta, transactionId, error
}
```

## Best Practices

- Prefer `dbTrace` to automatically capture duration and success.
- Use `projectResult` to log only aggregates (e.g., number of rows) instead of full result sets.
- Set `slowQueryThreshold` to highlight performance hotspots.
- Use `transactionId` correlation with `dbTransaction` to link related operations.
- For production, enable `attachStackOnError` for actionable diagnostics without adding try/catch around every DB call.

## Roadmap

- Optional driver helpers (`ispectify_hive`, `ispectify_drift`, `ispectify_sqflite`): tiny wrappers that call this API.
- Digest improvements and grouping.
- Optional global sinks/interceptors if needed.

## License

MIT (same as the main repository).