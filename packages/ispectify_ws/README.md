<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_ws.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify_ws">
      <img src="https://img.shields.io/pub/v/ispectify_ws?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
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
    <a href="https://pub.dev/packages/ispectify_ws/score">
      <img src="https://img.shields.io/pub/likes/ispectify_ws?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_ws/score">
      <img src="https://img.shields.io/pub/points/ispectify_ws?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify_ws">
      <img src="https://img.shields.io/pub/dm/ispectify_ws?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


**ispectify_ws** is a WebSocket interceptor for the [ISpect toolkit](#the-ispect-toolkit), built on top of the [`ws`](https://pub.dev/packages/ws) client. It captures every sent/received frame, exposes connection lifecycle events, and redacts sensitive data before logging.

- Frame-level capture for sent and received messages.
- Error and close-event logging with stack traces.
- Pluggable redaction — reuses the same engine as the HTTP interceptors.

## Install

```yaml
dependencies:
  ws: ^1.0.0
  ispectify: ^5.0.0-dev17
  ispectify_ws: ^5.0.0-dev17
```

## Quick start

```dart
import 'package:ws/ws.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

final interceptor = ISpectWSInterceptor(
  logger: logger,
  settings: const ISpectWSInterceptorSettings(
    enabled: true,
    printSentData: true,
    printReceivedData: true,
    printReceivedMessage: true,
    printErrorData: true,
    printErrorMessage: true,
  ),
);

final client = WebSocketClient(
  WebSocketOptions.common(interceptors: [interceptor]),
);

// The interceptor needs a back-reference to the client for lifecycle events.
interceptor.setClient(client);
```

## Settings

```dart
const settings = ISpectWSInterceptorSettings(
  enabled: true,
  printSentData: true,
  printReceivedData: true,
  printReceivedMessage: true,
  printErrorData: true,
  printErrorMessage: true,
  enableRedaction: true,
);
```

## Data redaction

Sensitive data is automatically masked before it reaches logs or observers. Redaction is **enabled by default** — built-in rules cover auth headers, tokens, passwords, API keys, cookies, PII (SSN, passport, driver's license), financial data (credit cards, IBAN), phone numbers, and more.

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
