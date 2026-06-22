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


`ispectify` is the logging core of the [ISpect toolkit](#the-ispect-toolkit). Pure Dart, no Flutter dependency. Use it in CLI tools, server-side Dart, and shared business-logic packages.

- Typed log entries with explicit severity levels and log-type keys.
- Filtering, bounded in-memory history, and configurable truncation.
- Trace extensions for async, sync, and stream operations with timing and outcome tagging.
- Observer hooks that forward selected events to your own sink.
- A built-in [redaction engine](#data-redaction) shared with the `ispectify_*` interceptor packages.

## Install

```yaml
dependencies:
  ispectify: ^6.0.0-dev.33
```

## Quick start

```dart
import 'package:ispectify/ispectify.dart';

final logger = ISpectLogger();

logger.info('Application started');
logger.warning('Cache miss, falling back to network');
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

Streaming-only, with no in-memory history. Use this when every event is forwarded to an observer:

```dart
final logger = ISpectLogger(
  options: const ISpectLoggerOptions(useHistory: false),
);
```

Filter by log-type key. Suppress noisy categories without changing call sites:

```dart
final logger = ISpectLogger(
  filter: ISpectFilter(logTypeKeys: {'analytics', 'route'}),
);
```

Filter by level. Drop `debug` and `verbose`, keep `info` and above:

```dart
final logger = ISpectLogger(
  logger: ISpectBaseLogger(
    filter: LogLevelRangeFilter(minLevel: LogLevel.info),
  ),
);
```

## Tracing

Trace extensions wrap work in a paired start/end log entry with duration, outcome, and an optional result projection. You get one-line "did this domain action succeed?" entries in the log viewer instead of a flood of unrelated logs.

Each trace call takes an `ISpectTraceCategory`. Pre-built ones (`networkCategory`, `dbCategory`, `authCategory`, `storageCategory`, `paymentCategory`, and the rest) live in `package:ispectify/ispectify.dart`, or you can declare your own.

```dart
const userRepoCategory = ISpectTraceCategory(
  id: 'user-repo',
  successKey: 'user-repo-ok',
  errorKey: 'user-repo-error',
);

final users = await logger.traceAsync<List<User>>(
  category: userRepoCategory,
  source: 'user_repository',
  operation: 'fetch_list',
  run: () => userRepository.fetchAll(),
  projectResult: (list) => {'count': list.length},
);
```

`traceSync` and `traceStream` are also available. Each one records the duration, the exception, and the stack trace on failure.

## Observers

Observers receive every log event in real time. Attach one per external sink.

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

Sensitive data is masked before it reaches logs or observers. Redaction is on by default. The built-in rules cover auth headers, tokens, passwords, API keys, cookies, common PII (SSN, passport, driver's license), financial data (credit cards, IBAN), and phone numbers.

The same redactor runs beyond the initial capture. Supported exports, clipboard helpers, cURL generation, and observer payloads all pass through the same pipeline before data leaves the debug session.

Redaction works best paired with focused capture. Keep body and header logging off unless you actually need the payload, and register project-specific keys for the business identifiers only your application understands.

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
  // Keys where the value is replaced entirely instead of edge-masked.
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
  // `?mobile=true` is a platform flag, not a phone number.
  ignoredKeys: {'mobile', 'platform_token'},
  ignoredValues: {'<test-token>', 'public-api-key'},
);
```

### Disabling

Each interceptor accepts `enableRedaction: false` on its settings object. See the per-package README for the exact settings type.

Only disable redaction in isolated local or deterministic test environments. Exported sessions and observer events should be handled according to the data they contain.


## Security

Exported logs are plain-text JSON. Do not write PII (emails, phone numbers, tokens) directly through `logger.info(...)`. Rely on the redaction engine when values flow through network interceptors, and sanitize user input before passing it to a manual log call. See [`docs/SECURITY.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md) for the data-handling policy.

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI: debug panel, log viewer, navigation observer, inspector integration. |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core: typed log entries, filtering, tracing, observers. |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction. |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction. |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | Provider-agnostic WebSocket capture (any client) with automatic redaction. |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing for SQL, ORMs, and KV stores. |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event, state, transition, and error observer. |
| [`ispectify_riverpod`](https://pub.dev/packages/ispectify_riverpod) | Riverpod provider add, update, dispose, and failure observer. |


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
