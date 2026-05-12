<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify">
      <img src="https://img.shields.io/pub/v/ispectify?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
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
    <a href="https://pub.dev/packages/ispectify/score">
      <img src="https://img.shields.io/pub/likes/ispectify?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify/score">
      <img src="https://img.shields.io/pub/points/ispectify?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify">
      <img src="https://img.shields.io/pub/dm/ispectify?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


**ispectify** is the logging backbone of the [ISpect toolkit](#the-ispect-toolkit). Pure Dart, no Flutter — usable in CLI tools, server-side Dart, and shared business-logic packages.

- Typed log entries with explicit severity levels and log-type keys.
- Filtering, in-memory history, and custom truncation.
- Trace extensions for async / sync / stream operations with timing and outcome tagging.
- Observer hooks to forward selected events into internal tools through your own adapter.
- Built-in [redaction engine](#data-redaction) shared across the `ispectify_*` interceptor packages.

## Install

```yaml
dependencies:
  ispectify: ^5.0.0-dev47
```

## Quick start

```dart
import 'package:ispectify/ispectify.dart';

final logger = ISpectLogger();

logger.info('Application started');
logger.warning('Cache miss — falling back to network');
logger.error('Payment gateway returned 502', exception, stackTrace);
```

Custom log types:

```dart
logger.log(
  'User signed in',
  logLevel: LogLevel.info,
  type: const ISpectLogType('auth'),
);
```

## Configuration

```dart
final logger = ISpectLogger(
  options: ISpectLoggerOptions(
    enabled: true,
    useHistory: true,
    useConsoleLogs: true,
    maxHistoryItems: 5000,
    logTruncateLength: 4000,
  ),
);
```

**Streaming-only** (no in-memory history — useful when every event is forwarded to an observer):

```dart
final logger = ISpectLogger(
  options: const ISpectLoggerOptions(useHistory: false),
);
```

**Filter by log-type key** (suppress noisy categories without changing call sites):

```dart
final logger = ISpectLogger(
  filter: ISpectFilter(logTypeKeys: {'analytics', 'route'}),
);
```

**Filter by level** (drop `debug`/`verbose`, keep `info` and above):

```dart
final logger = ISpectLogger(
  logger: ISpectBaseLogger(
    filter: LogLevelRangeFilter(minLevel: LogLevel.info),
  ),
);
```

## Tracing

Trace extensions wrap work in a start/end log pair with duration, outcome, and optional result projection — so you can see one-line "did this domain action succeed?" entries in the log viewer.

```dart
final users = await logger.traceAsync<List<User>>(
  source: 'user_repository',
  operation: 'fetch_list',
  run: () => userRepository.fetchAll(),
  projectResult: (list) => {'count': list.length},
);
```

Also available: `traceSync`, `traceStream`. Each reports duration, exception, and stack trace on failure.

## Observers

Observers receive every log event in real time — attach one per external sink:

```dart
class GrafanaObserver extends ISpectObserver {
  const GrafanaObserver();

  @override
  void onLog(ISpectLogData data) { /* ship to Loki */ }

  @override
  void onError(ISpectLogData err) { /* ship to Loki */ }

  @override
  void onException(ISpectLogData err) { /* ship to Loki */ }
}

logger.addObserver(const GrafanaObserver());
```

## Data redaction

Sensitive data is automatically masked before it reaches logs or observers. Redaction is **enabled by default** — built-in rules cover auth headers, tokens, passwords, API keys, cookies, PII (SSN, passport, driver's license), financial data (credit cards, IBAN), phone numbers, and more.

The same redaction model is used beyond initial capture: supported exports, clipboard helpers, cURL generation, and observer payloads can pass through the shared redaction pipeline before data leaves the app/debug session.

Redaction works best together with focused capture. Keep body/header logging disabled when payload contents are not needed, and register project-specific keys for business identifiers that only your application understands.

### Custom keys and patterns

```dart
import 'package:ispectify/ispectify.dart';

final redactor = RedactionService(
  sensitiveKeys: {
    ...defaultSensitiveKeys,
    'x-custom-secret',
    'internal_token',
  },
  sensitiveKeyPatterns: [
    RegExp(r'my_app_secret_\w+', caseSensitive: false),
  ],
  // Keys where the value is replaced entirely (not edge-masked).
  fullyMaskedKeys: {'filename'},
  placeholder: '***',
  visibleEdgeLength: 3,
  redactBinary: true,
  redactBase64: true,
);
```

### Ignoring defaults

```dart
final redactor = RedactionService(
  // e.g., ?mobile=true is a platform flag, not a phone number.
  ignoredKeys: {'mobile', 'platform_token'},
  ignoredValues: {'<test-token>', 'public-api-key'},
);
```

### Disabling

Each interceptor accepts `enableRedaction: false` on its settings object. See the per-package README for the exact settings type.

Only disable redaction in isolated local or deterministic test environments. Exported sessions and observer events should be handled according to the data they contain.


## Security

Exported logs are plain-text JSON. Never write PII (emails, phone numbers, tokens) directly via `logger.info(...)` — rely on the redaction engine when values flow through network interceptors, and sanitize user input before logging it manually. See [`docs/SECURITY.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md) for the recommended data-handling policy.

## The ISpect toolkit

ISpect is a modular monorepo. Install only what your project needs — each package works independently.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI — debug panel, log viewer, navigation observer, inspector integration |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector — sizes, constraints, decorations, compare mode, color picker |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core — typed log entries, filtering, tracing, observers |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | WebSocket traffic capture with automatic redaction |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing (SQL, ORM, KV stores) |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event / state / transition observer |


## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT — see [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
