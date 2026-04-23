<!-- partial:header -->

**ispectify_db** adds passive database observability to the [ISpect toolkit](#the-ispect-toolkit). It traces SQL statements, ORM operations, and KV-store calls through a single `dbTrace` extension — with timing, row counts, slow-query detection, and redaction.

- Works with any driver: sqflite, drift, Isar, ObjectBox, shared_preferences, hive, etc. — just wrap the call.
- Redaction of argument values by configured keys.
- Slow-query threshold triggers a separate log entry so perf outliers stand out.
- Optional stack trace capture on errors, without paying the cost on the hot path.
- Pure Dart — no Flutter binding required.

## Install

```yaml
dependencies:
  ispectify: ^{{version}}
  ispectify_db: ^{{version}}
```

## Quick start

Configure once at startup:

```dart
import 'package:ispectify_db/ispectify_db.dart';

ISpectDbCore.config = const ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  attachStackOnError: true,
  slowQueryThreshold: Duration(milliseconds: 400),
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
);
```

`source` and `operation` become the grouping key in the log viewer; `projectResult` lets you record "just the counts" without dumping row contents.

## Configuration

| Field | Default | What it does |
| --- | --- | --- |
| `sampleRate` | `1.0` | Fraction of calls to log (e.g. `0.1` = 10%). |
| `redact` | `true` | Mask sensitive keys in `args` and `statement`. |
| `redactKeys` | built-in set | Override the redaction key list. |
| `attachStackOnError` | `true` | Capture and log stack trace on failure. |
| `slowQueryThreshold` | `null` | If set, durations above the threshold are re-logged as `db-slow-query`. |

```dart
ISpectDbCore.config = const ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
  slowQueryThreshold: Duration(milliseconds: 250),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
