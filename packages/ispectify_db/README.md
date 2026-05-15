<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_db.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify_db">
      <img src="https://img.shields.io/pub/v/ispectify_db?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&labelColor=0360a9&color=2ab7f6" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=for-the-badge&logo=github&labelColor=0360a9&color=2ab7f6" alt="GitHub stars">
    </a>
    <a href="https://codecov.io/gh/yelmuratoff/ispect">
      <img src="https://img.shields.io/codecov/c/github/yelmuratoff/ispect?style=for-the-badge&logo=codecov&labelColor=0360a9&color=2ab7f6" alt="Coverage">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispectify_db/score">
      <img src="https://img.shields.io/pub/likes/ispectify_db?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_db/score">
      <img src="https://img.shields.io/pub/points/ispectify_db?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify_db">
      <img src="https://img.shields.io/pub/dm/ispectify_db?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


`ispectify_db` adds passive database observability to the [ISpect toolkit](#the-ispect-toolkit). It traces SQL statements, ORM operations, and KV-store calls through a single `dbTrace` extension with timing, row counts, slow-query detection, and redaction.

- Works with any driver. sqflite, drift, Isar, ObjectBox, shared_preferences, hive, and the rest. Wrap the call and the tracing is automatic.
- Argument redaction by configured keys.
- A slow-query threshold emits a separate log entry so perf outliers stand out.
- Optional stack trace capture on errors, paid for only when an error happens.
- Pure Dart. No Flutter binding required.

## Install

```yaml
dependencies:
  ispectify: ^5.0.0-dev54
  ispectify_db: ^5.0.0-dev54
```

## Quick start

Configure once at startup:

```dart
import 'package:ispectify_db/ispectify_db.dart';

ISpectDbCore.config = const ISpectDbConfig(
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
);
```

`source` and `operation` become the grouping key in the log viewer. `projectResult` lets you record "just the counts" instead of dumping row contents.

## Configuration

| Field | Default | What it does |
| --- | --- | --- |
| `sampleRate` | `1.0` | Fraction of calls to log. `0.1` keeps 10% of them. |
| `redact` | `true` | Mask sensitive keys in `args` and `statement`. |
| `redactKeys` | built-in set | Override the redaction key list. |
| `attachStackOnError` | `true` | Capture and log a stack trace on failure. |
| `slowThreshold` | `null` | Re-emit durations above the threshold as a `db-slow-query` entry. (Renamed from `slowQueryThreshold` in 5.0.) |

```dart
ISpectDbCore.config = const ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
  slowThreshold: Duration(milliseconds: 250),
);
```

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI: debug panel, log viewer, navigation observer, inspector integration. |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core: typed log entries, filtering, tracing, observers. |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction. |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction. |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | WebSocket traffic capture with automatic redaction. |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing for SQL, ORMs, and KV stores. |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event, state, transition, and error observer. |


## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT. See [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
