<!-- partial:header -->

`ispectify_db` adds passive database observability to the [ISpect toolkit](#the-ispect-toolkit). It traces SQL statements, ORM operations, and KV-store calls through a single `dbTrace` extension with timing, row counts, slow-query detection, and redaction.

- Works with any driver. sqflite, drift, Isar, ObjectBox, shared_preferences, hive, and the rest. Wrap the call and the tracing is automatic.
- Argument redaction by configured keys.
- A slow-query threshold flags perf outliers on the trace entry so they stand out.
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
  captureMode: DiagnosticCaptureMode.balanced,
  resourceLimits: DiagnosticResourceLimits.constrained,
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

| Field                | Default       | What it does                                                                                                                       |
| -------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `sampleRate`         | `null`        | Fraction of successful calls to log. `null` and `1.0` both keep all of them; `0.1` keeps 10%.                                      |
| `redact`             | `true`        | Mask sensitive keys in `args` and `statement`.                                                                                     |
| `redactKeys`         | built-in set  | Override the redaction key list.                                                                                                   |
| `captureMode`        | `balanced`    | Allow guarded, bounded typed-value and error formatting; use `strict` to disable application formatters.                           |
| `resourceLimits`     | logger policy | Override database scalar, diagnostic, metadata, traversal, and output budgets for this trace.                                      |
| `attachStackOnError` | `false`       | Capture and log a stack trace on failure.                                                                                          |
| `slowThreshold`      | `null`        | Adds a `slow` flag to the trace entry, `true` when the duration exceeds the threshold. (Renamed from `slowQueryThreshold` in 5.0.) |

```dart
const dbConfig = ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
  slowThreshold: Duration(milliseconds: 250),
);
```

`redactKeys` is an explicit local replacement for this trace. Omit it to use the current global `ISpectRedaction.service`.
If a copied config already has local limits, use
`dbConfig.copyWith(inheritResourceLimits: true)` to clear that override and
resume following the logger policy.

<!-- partial:redaction -->

<!-- partial:install_matrix -->

<!-- partial:footer -->
