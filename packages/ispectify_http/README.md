<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_http.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify_http">
      <img src="https://img.shields.io/pub/v/ispectify_http?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
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
    <a href="https://pub.dev/packages/ispectify_http/score">
      <img src="https://img.shields.io/pub/likes/ispectify_http?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_http/score">
      <img src="https://img.shields.io/pub/points/ispectify_http?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify_http">
      <img src="https://img.shields.io/pub/dm/ispectify_http?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


`ispectify_http` is an [`http_interceptor`](https://pub.dev/packages/http_interceptor) interceptor for the [ISpect toolkit](#the-ispect-toolkit). It captures requests made through the `package:http` client, pairs them into transactions, and redacts sensitive data before logging.

- Request, response, and error capture with headers, body, status, and duration.
- Redaction of auth headers, tokens, PII, and financial data. On by default.
- Works with any `InterceptedClient` from `http_interceptor`.

## Install

```yaml
dependencies:
  http: ^1.0.0
  http_interceptor: ^2.0.0
  ispectify: ^5.0.2
  ispectify_http: ^5.0.2
```

## Quick start

```dart
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispect/ispect.dart';
import 'package:ispectify_http/ispectify_http.dart';

final client = http_interceptor.InterceptedClient.build(interceptors: []);

ISpect.run(
  () => runApp(const MyApp()),
  logger: logger,
  onInit: () {
    client.interceptors.add(
      ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
        ),
      ),
    );
  },
);
```

## Settings

`ISpectHttpInterceptorSettings` mirrors the Dio version. Headers and body capture toggles, with `enableRedaction: true` by default.

```dart
const settings = ISpectHttpInterceptorSettings(
  printRequestHeaders: true,
  printRequestData: true,
  printResponseHeaders: false,
  printResponseData: true,
  enableRedaction: true,
);
```

Preset factories and a builder are also available. See `ISpectHttpInterceptorSettingsBuilder` for the `development()`, `staging()`, and `production()` presets.

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


Custom redactor:

```dart
ISpectHttpInterceptor(
  logger: logger,
  redactor: RedactionService(
    sensitiveKeys: {...defaultSensitiveKeys, 'x-internal-token'},
  ),
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
