<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_dio.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify_dio">
      <img src="https://img.shields.io/pub/v/ispectify_dio?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
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
    <a href="https://pub.dev/packages/ispectify_dio/score">
      <img src="https://img.shields.io/pub/likes/ispectify_dio?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_dio/score">
      <img src="https://img.shields.io/pub/points/ispectify_dio?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify_dio">
      <img src="https://img.shields.io/pub/dm/ispectify_dio?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


**ispectify_dio** is a [Dio](https://pub.dev/packages/dio) interceptor for the [ISpect toolkit](#the-ispect-toolkit). It captures every request/response, pairs them into correlated transactions, and redacts sensitive data before logging.

- Request / response / error capture with headers, body, status, and duration.
- Per-call redaction of auth headers, tokens, PII, and credit-card data (on by default).
- Builder and factory presets for development, staging, and production setups.
- Works with any `Dio` instance — attach the interceptor and you're done.

## Install

```yaml
dependencies:
  dio: ^5.0.0
  ispectify: ^5.0.0-dev34
  ispectify_dio: ^5.0.0-dev34
```

## Quick start

```dart
import 'package:dio/dio.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

ISpect.run(
  () => runApp(const MyApp()),
  logger: logger,
  onInit: () {
    dio.interceptors.add(
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestData: true,
          printResponseData: true,
        ),
      ),
    );
  },
);
```

## Settings

`ISpectDioInterceptorSettings` controls which slices of each call are captured and whether they are redacted before logging. `enableRedaction` defaults to **`true`** on every constructor.

```dart
const settings = ISpectDioInterceptorSettings(
  printRequestHeaders: true,
  printRequestData: true,
  printResponseHeaders: false,
  printResponseData: true,
  enableRedaction: true,
);
```

### Preset factories

```dart
// Verbose — full payloads, no redaction. Only for local dev.
final dev = ISpectDioInterceptorSettingsBuilder.development().build();

// Redacted — conservative defaults, body capture off.
final prod = ISpectDioInterceptorSettingsBuilder.production().build();

// Middle ground — useful for staging environments.
final staging = ISpectDioInterceptorSettingsBuilder.staging().build();
```

### Builder

```dart
final settings = ISpectDioInterceptorSettingsBuilder()
    .withRequestHeaders()
    .withResponseHeaders()
    .withoutRedaction() // not recommended — see "Data redaction" below.
    .build();
```

## Data redaction

Sensitive data is automatically masked before it reaches logs or observers. Redaction is **enabled by default** — built-in rules cover auth headers, tokens, passwords, API keys, cookies, PII (SSN, passport, driver's license), financial data (credit cards, IBAN), phone numbers, and more.

Redaction is a safety layer, not a substitute for data minimization. Prefer disabling body/header capture when payload contents are not needed, and add project-specific keys for business identifiers that only your application understands.

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

Only disable redaction in isolated local or deterministic test environments. Exported sessions and observer events should be treated as sensitive artifacts even when redaction is enabled.


Disable redaction for a single interceptor instance (not recommended — use only for deterministic replay in test environments):

```dart
ISpectDioInterceptor(
  logger: logger,
  settings: const ISpectDioInterceptorSettings(enableRedaction: false),
);
```

Supply a custom `RedactionService`:

```dart
ISpectDioInterceptor(
  logger: logger,
  redactor: RedactionService(
    sensitiveKeys: {...defaultSensitiveKeys, 'x-tenant-token'},
  ),
);
```

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
