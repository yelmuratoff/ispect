<!-- partial:header -->

`ispectify_db` adds passive database observability to the [ISpect toolkit](#the-ispect-toolkit). It traces SQL statements, ORM operations, and KV-store calls through a single `dbTrace` extension with timing, row counts, slow-query detection, and redaction.

- Works with any driver. sqflite, drift, Isar, ObjectBox, shared_preferences, hive, and the rest. Wrap the call and the tracing is automatic.
- Argument redaction by configured keys.
- A slow-query threshold emits a separate log entry so perf outliers stand out.
- Optional stack trace capture on errors, paid for only when an error happens.
- Pure Dart. No Flutter binding required.

## Install

```yaml
dependencies:
  ispectify: ^{{version}}
  ispectify_db: ^{{version}}
```

## Quick start

Pass configuration at the traced call site:

```dart
import 'package:ispectify_db/ispectify_db.dart';

const dbConfig = ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  attachStackOnError: true,
  slowThreshold: Duration(milliseconds: 400),
);
```

Then wrap each storage call with `dbTrace`:

```dart
import 'package:sqflite/sqflite.dart';

final rows = await ISpect.logger.dbTrace<List<Map<String, Object?>>>(
  source: 'sqflite',
  operation: 'query',
  statement: 'SELECT * FROM users WHERE id = ?',
  args: [userId],
  table: 'users',
  run: () => db.rawQuery('SELECT * FROM users WHERE id = ?', [userId]),
  projectResult: (rows) => {'rows': rows.length},
  config: dbConfig,
);
```

`source` and `operation` become the grouping key in the log viewer. `projectResult` lets you record "just the counts" instead of dumping row contents.

## Configuration

| Field                | Default      | What it does                                                                                                  |
| -------------------- | ------------ | ------------------------------------------------------------------------------------------------------------- |
| `sampleRate`         | `1.0`        | Fraction of calls to log. `0.1` keeps 10% of them.                                                            |
| `redact`             | `true`       | Mask sensitive keys in `args` and `statement`.                                                                |
| `redactKeys`         | built-in set | Override the redaction key list.                                                                              |
| `attachStackOnError` | `true`       | Capture and log a stack trace on failure.                                                                     |
| `slowThreshold`      | `null`       | Re-emit durations above the threshold as a `db-slow-query` entry. (Renamed from `slowQueryThreshold` in 5.0.) |

```dart
const dbConfig = ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
  slowThreshold: Duration(milliseconds: 250),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
