<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_db.md
  Regenerate: dart run tool/bin/ispect_tool.dart readme
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
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/production_safety.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/production_safety.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Production%20Safety&labelColor=0360a9" alt="Production Safety workflow">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/test.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/test.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Test%20%26%20Analyze&labelColor=0360a9" alt="Test and Analyze workflow">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/deploy-web-logs-viewer.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/deploy-web-logs-viewer.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Web%20Demo%20Deploy&labelColor=0360a9" alt="Deploy Web Logs Viewer workflow">
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
- A slow-query threshold flags perf outliers on the trace entry so they stand out.
- Optional stack trace capture on errors, paid for only when an error happens.
- Pure Dart. No Flutter binding required.

## Install

```yaml
dependencies:
  ispectify: ^7.0.0-rc.4
  ispectify_db: ^7.0.0-rc.4
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

## Data redaction

Sensitive data is masked before it reaches logs or observers. Redaction is on by default. The built-in rules cover auth headers, tokens, passwords, API keys, cookies, common PII (SSN, passport, driver's license), financial data (credit cards, IBAN), and phone numbers.

The default policy is a single source of truth. Configure it once and core logs, traces, persistence, network and database adapters, BLoC and Riverpod observers, supported exports, clipboard helpers, and cURL generation resolve it when each diagnostic operation runs.

Redaction works best paired with deliberate capture. Use the integration's `metadataOnly()` or compact preset when payload values are unnecessary, and register project-specific keys for the business identifiers only your application understands.

The default `DiagnosticCaptureMode.balanced` keeps diagnostics useful by
allowing guarded `toJson()` and `toString()` capture. The result is bounded
immediately and redacted before it leaves the active pipeline. Select
`DiagnosticCaptureMode.strict` when application-defined formatters must never
run. Network `metadataOnly()` and `production()` presets, plus BLoC/Riverpod
`compact`, select strict capture automatically. Persistence, export, and
observer delivery do not re-run formatters after capture.

### Global configuration

```dart
import 'package:ispectify/ispectify.dart';

ISpectRedaction.configure(
  service: RedactionService(
    additionalSensitiveKeys: {
      'x-custom-secret',
      'internal_token',
    },
    additionalSensitiveKeyPatterns: [
      RegExp(r'my_app_secret_\w+', caseSensitive: false),
    ],
    fullyMaskedKeys: {'filename'},
    placeholder: '***',
    visibleEdgeLength: 3,
  ),
);
```

`additionalSensitiveKeys` and `additionalSensitiveKeyPatterns` extend the built-in policy. Use `sensitiveKeys` or `sensitiveKeyPatterns` only when you intentionally want to replace the corresponding defaults:

```dart
final replacementPolicy = RedactionService(
  sensitiveKeys: {
    'x-custom-secret',
    'internal_token',
  },
  sensitiveKeyPatterns: [
    RegExp(r'my_app_secret_\w+', caseSensitive: false),
  ],
);
```

Flutter apps can pass the same policy as `ISpect.run(redactionService: ...)`; `ISpect.dispose()` restores the policy that was active before that run. An explicit `RedactionService` supplied to one integration stays local and takes precedence over the global policy. Existing integrations without an explicit service pick up later global reconfiguration. The policy is scoped to the current Dart isolate.

### Local exceptions

```dart
final redactor = RedactionService(
  ignoredKeys: {'mobile', 'platform_token'},
  ignoredValues: {'<test-token>', 'public-api-key'},
);
```

### Disabling

`ISpectRedaction.configure(enabled: false)` is the global content-masking
opt-out. Each interceptor also accepts `enableRedaction: false` on its settings
object for a local opt-out. Size limits, private-storage checks, the selected
capture mode, and the compile-time `ISPECT_ENABLED` gate remain enforced.

Only disable redaction in isolated local or deterministic test environments. Exported sessions and observer events should be handled according to the data they contain.

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package                                                             | What it does                                                                                    |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`ispect`](https://pub.dev/packages/ispect)                         | Flutter UI: debug panel, log viewer, navigation observer, inspector integration.                |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout)           | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify)                   | Pure-Dart logging core: typed log entries, filtering, tracing, observers.                       |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio)           | Dio HTTP interceptor with automatic redaction.                                                  |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http)         | `http` package interceptor with automatic redaction.                                            |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws)             | Provider-agnostic WebSocket capture (any client) with automatic redaction.                      |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db)             | Database operation tracing for SQL, ORMs, and KV stores.                                        |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc)         | BLoC event, state, transition, and error observer.                                              |
| [`ispectify_riverpod`](https://pub.dev/packages/ispectify_riverpod) | Riverpod provider add, update, dispose, and failure observer.                                   |

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
