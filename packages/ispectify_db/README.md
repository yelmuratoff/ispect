<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Passive database logging utilities for the ISpect toolkit. Keep your DB calls as-is and simply log intents, timings, and results. Works with SQL and key-value stores (sqflite, drift, hive, shared_preferences, etc.) without importing them in this package.</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_db">
      <img src="https://img.shields.io/pub/v/ispectify_db.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_db/score">
      <img src="https://img.shields.io/pub/likes/ispectify_db?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_db/score">
      <img src="https://img.shields.io/pub/points/ispectify_db?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## TL;DR

No adapters required (yet) — call one or two methods. Minimal API, maximum flexibility. Redaction, sampling, truncation, SQL digest, slow query mark, transaction markers.

## 🏗️ Architecture

ispectify_db integrates with the ISpect logging ecosystem:

| Component | Description |
|-----------|-----------|
| **DB Logger** | Core logging interface for database operations |
| **Configuration** | Global settings for redaction, sampling, and thresholds |
| **Transaction Support** | Correlated logging for multi-operation transactions |
| **Performance Tracking** | Automatic duration measurement and slow query detection |
| **ISpect Integration** | Structured events compatible with ISpect UI |

## Overview

> **ispectify_db** is the passive database logging utilities for the ISpect toolkit

ispectify_db provides passive logging for database operations without requiring changes to your existing database code. Simply wrap your DB calls with logging methods to capture intents, timings, results, and errors. It integrates seamlessly with the ISpect debugging toolkit and supports various database drivers and key-value stores.

### Key Features

- No adapters required (yet) — call one or two methods
- Minimal API, maximum flexibility
- Redaction, sampling, truncation, SQL digest
- Slow query mark, transaction markers
- Works with SQL and key-value stores (sqflite, drift, hive, shared_preferences, etc.)
- Automatic duration and success/error capture
- Structured event logging with ISpect UI integration

## API Reference

### Core Methods

- `ISpectDbCore.config = ISpectDbConfig(...)` — set global behavior
- `ISpectify.db(...)` — emit a single DB event
- `ISpectify.dbTrace<T>(...)` — wrap a Future and emit on completion
- `ISpectify.dbStart(...)` / `ISpectify.dbEnd(...)` — manual span around code
- `ISpectify.dbTransaction(...)` — run with shared transactionId

### Common Fields

- `source`: driver name (sqflite, drift, hive, shared_prefs, etc.)
- `operation`: query, insert, update, delete, get, put, remove, etc.
- `statement`: SQL string (truncated and digested)
- `target` / `table` / `key`: operation target
- `args` / `namedArgs`: query parameters
- `value` or `projectResult`: logged result
- `meta`: additional context

### Redaction & Truncation

Redaction replaces values for keys in `redactKeys` (case-insensitive). Truncation applies to long strings and preserves structure.

### Sampling

Per-call or global sampling to control log volume.

### Slow Queries

Mark operations exceeding `slowQueryThreshold`.

## Structured Events

Events use ISpect-recognized keys:
- `db-query`: read operations
- `db-result`: successful writes
- `db-error`: failed operations

Additional data includes source, operation, duration, success, etc.

## Best Practices

- Prefer `dbTrace` for automatic capture
- Use `projectResult` for large results
- Set `slowQueryThreshold` for performance monitoring
- Use `dbTransaction` for correlated operations
- Enable `attachStackOnError` for diagnostics

## Installation

Add ispectify_db to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_db: ^4.4.0-dev01
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

</details>

## 🚀 Quick Start

```dart
import 'package:ispect/ispect.dart';
import 'package:ispectify_db/ispectify_db.dart';

// Configure (optional)
ISpectDbCore.config = const ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  attachStackOnError: true,
  enableTransactionMarkers: false,
  slowQueryThreshold: Duration(milliseconds: 400),
);

// Log a simple event
ISpect.logger.db(
  source: 'SharedPreferences',
  operation: 'write',
  target: 'language',
  value: 'eu',
);

// Wrap an async DB call to capture duration + success/error
final rows = await ISpect.logger.dbTrace<List<Map<String, Object?>>>(
  source: 'sqflite',
  operation: 'query',
  statement: 'SELECT * FROM users WHERE id = ?',
  args: [userId],
  table: 'users',
  run: () => db.rawQuery('SELECT * FROM users WHERE id = ?', [userId]),
  projectResult: (rows) => {'rows': rows.length},
);

// Manual start/end
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

// Transaction markers
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

### Minimal Setup

## Examples

See the [example/](example/) directory for complete usage examples and integration patterns.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispect](../ispect) - Main debugging interface
- [ispectify](../ispectify) - Core logging system
- [ispectify_dio](../ispectify_dio) - HTTP client integration
- [ispectify_http](../ispectify_http) - HTTP client integration
- [ispectify_ws](../ispectify_ws) - WebSocket integration

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>