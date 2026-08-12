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


`ispectify_dio` is a [Dio](https://pub.dev/packages/dio) interceptor for the [ISpect toolkit](#the-ispect-toolkit). It captures requests and responses, pairs them into correlated transactions by a request ID, and redacts sensitive data before logging.

- Request, response, and error capture with headers, body, status, and duration.
- Per-call redaction of auth headers, tokens, PII, and credit-card data. On by default.
- Builder and factory presets for development, staging, and production setups.
- Works with any `Dio` instance. Attach the interceptor and the rest is automatic.

## Install

```yaml
dependencies:
  dio: ^5.0.0
  ispectify: ^7.0.0-dev8
  ispectify_dio: ^7.0.0-dev8
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
      ),
    );
  },
);
```

## Settings

`ISpectDioInterceptorSettings` captures headers, bodies, messages, and errors by default so the first diagnostic session is useful without extra configuration. Captured values are bounded and redacted before logging; `enableRedaction` defaults to `true` on every constructor.

```dart
const settings = ISpectDioInterceptorSettings(
  logRequests: true,
  logResponses: true,
  printRequestHeaders: true,
  printRequestData: true,
  printResponseHeaders: true,
  printResponseData: true,
  enableRedaction: true,
  captureMode: DiagnosticCaptureMode.balanced,
  resourceLimits: DiagnosticResourceLimits.constrained,
);
```

Balanced capture lets typed request and response values contribute a guarded,
bounded `toJson()` snapshot before redaction. Set
`captureMode: DiagnosticCaptureMode.strict` when application-defined
formatters must never run.

### Preset factories

```dart
// Verbose payload capture with redaction still enabled.
final dev = ISpectDioInterceptorSettingsBuilder.development().build();

final hardened =
    ISpectDioInterceptorSettingsBuilder.metadataOnly().build();

// Redacted errors only. Routine request/response records are not retained.
final prod = ISpectDioInterceptorSettingsBuilder.production().build();

// Middle ground for staging environments.
final staging = ISpectDioInterceptorSettingsBuilder.staging().build();
```

`metadataOnly()` and `production()` select strict capture. `development()` and
`staging()` keep balanced capture. A custom builder can switch explicitly with
`withStrictCapture()` or `withBalancedCapture()`.
Use `withResourceLimits(...)` for an interceptor-local budget, or
`withInheritedResourceLimits()` to return to the logger policy.
`NetworkInterceptorDefaults` is the shared source of truth used by direct
settings construction and every network settings builder.

### Builder

```dart
final settings = ISpectDioInterceptorSettingsBuilder()
    .withoutResponses()
    .withoutRequestHeaders()
    .withoutRequestData()
    .withoutRedaction() // not recommended, see "Data redaction" below.
    .build();
```

`logRequests` and `logResponses` decide whether routine records are retained.
Body and header capture is on by default and passes through the active
redaction policy. The `print*` fields can omit specific retained fields, while
the `metadataOnly()` preset opts into stronger data minimization without
disabling request/response visibility.
Concrete settings `copyWith` methods and builders expose the retention
controls. Pass `inheritResourceLimits: true` to `copyWith` to clear a local
budget. An attached Dio interceptor can update the same shared fields at
runtime with `configure(...)`, including `enabled`, retention, capture mode,
resource limits, and individual payload fields.

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


Disable redaction on a single interceptor instance (only for deterministic replay in test environments):

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
    additionalSensitiveKeys: {'x-tenant-token'},
  ),
);
```

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
