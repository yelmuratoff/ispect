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
  ispectify: ^7.0.0-rc.3
  ispectify_http: ^7.0.0-rc.3
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
      ),
    );
  },
);
```

> Register `ISpectHttpInterceptor` **last** in the `interceptors` list. Request/response correlation is keyed on the `BaseRequest` instance, and `http_interceptor` lets each interceptor return a new request object. If an interceptor registered after it rebuilds the request, the response can't be matched and stays "Pending".

## Settings

`ISpectHttpInterceptorSettings` mirrors the Dio version. Headers and bodies are
captured and redacted by default, and `enableRedaction` defaults to `true`.

```dart
const settings = ISpectHttpInterceptorSettings(
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

Balanced capture keeps ordinary URLs and prepared typed values useful through
guarded, bounded formatting before redaction. Set
`captureMode: DiagnosticCaptureMode.strict` when application-defined
formatters must never run.

Preset factories and a builder are also available. Use
`ISpectHttpInterceptorSettingsBuilder.metadataOnly()` to retain request and
response metadata while omitting bodies and headers. The `development()`,
`staging()`, and `production()` presets remain available for environment-based
policies.

`metadataOnly()` and `production()` select strict capture. `development()` and
`staging()` keep balanced capture. Builders also expose
`withStrictCapture()` and `withBalancedCapture()`.
Use `withResourceLimits(...)` for an interceptor-local budget, or
`withInheritedResourceLimits()` to return to the logger policy.
`NetworkInterceptorDefaults` is the shared source of truth used by direct
settings construction and every network settings builder.

`logRequests` and `logResponses` control whether routine records are retained;
the production preset disables both and keeps redacted errors. The `print*`
flags can omit bodies, headers, or messages from retained console and metadata
fields. Full capture is the default and keeps redaction on; individual flags
and the `metadataOnly()` preset provide opt-in minimization. Use the
concrete settings `copyWith` or builder for these retention controls; the
attached interceptor's `configure(...)` method exposes the same shared capture
fields at runtime. Pass `inheritResourceLimits: true` to either `copyWith` or
`configure` to return resource-budget ownership to the logger.

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

Custom redactor:

```dart
ISpectHttpInterceptor(
  logger: logger,
  redactor: RedactionService(
    additionalSensitiveKeys: {'x-internal-token'},
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
