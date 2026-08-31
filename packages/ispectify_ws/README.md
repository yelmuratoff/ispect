<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_ws.md
  Regenerate: dart run tool/bin/ispect_tool.dart readme
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

`ispectify_ws` is the provider-agnostic WebSocket diagnostics layer for the [ISpect toolkit](#the-ispect-toolkit). It captures sent and received frames, connection-state transitions, and errors — for **any** WebSocket client — and redacts sensitive data before logging. The published package depends only on `ispectify`; you keep your own WebSocket client dependency.

- Frame-level capture for sent and received messages (`ws-sent` / `ws-received`).
- Connection lifecycle logging via `ws-state` (connecting / open / closing / closed / reconnecting).
- Error logging with stack traces (`ws-error`); one correlation id per connection session.
- Same redaction engine as the HTTP interceptors.

## Install

```yaml
dependencies:
  ispectify: ^7.0.0-rc.8
  ispectify_ws: ^7.0.0-rc.8
  # plus your WebSocket client, e.g.
  # ws: ^1.0.0  |  web_socket_channel: ^3.0.0  |  socket_io_client: ^3.0.0
```

## Quick start

Bind any client to the `WsDiagnosticsSink` port. Metrics and state are optional — push whatever your client can report:

```dart
import 'package:ispect/ispect.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

final diagnostics = WsDiagnostics(logger: ISpect.logger);

diagnostics
  ..newConnection() // starts a fresh correlation session
  ..onStateChanged(WsConnectionState.open, url: url);

channel.stream.listen(
  (message) => diagnostics.onReceived(message, url: url),
  onError: (Object e, StackTrace st) => diagnostics.onError(e, st, url: url),
  onDone: () => diagnostics.onStateChanged(WsConnectionState.closed, url: url),
);
// Outbound: call diagnostics.onSent(data, url: url) before sending a frame.
```

## Ready-to-copy adapters

The package example ships thin adapters that wire a concrete client to `WsDiagnostics` — copy the one you need into your app (and add that client to your own `pubspec.yaml`):

| Client                                                              | Adapter                                                        |
| ------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`ws`](https://pub.dev/packages/ws) (plugfox)                       | `example/lib/interceptors/ws_interceptor.dart`                 |
| [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) | `example/lib/interceptors/web_socket_channel_interceptor.dart` |
| [`socket_io_client`](https://pub.dev/packages/socket_io_client)     | `example/lib/interceptors/socket_io_interceptor.dart`          |

> Migrating from 5.x? `ISpectWSInterceptor` moved out of the published package into `example/lib/interceptors/ws_interceptor.dart`. Copy it in and add `ws` to your app — `ISpectWSInterceptorSettings` and the `ws-sent` / `ws-received` / `ws-error` keys are unchanged. See `docs/DEPRECATIONS.md`.

## Settings

```dart
const settings = ISpectWSInterceptorSettings(
  enabled: true,
  logRequests: true,  // sent frames
  logResponses: true, // received frames
  printSentData: true,
  printReceivedData: true,
  printStateData: true,
  printReceivedMessage: true,
  printErrorData: true,
  printErrorMessage: true,
  enableRedaction: true,
  captureMode: DiagnosticCaptureMode.balanced,
  resourceLimits: DiagnosticResourceLimits.constrained,
);

final diagnostics = WsDiagnostics(logger: ISpect.logger, settings: settings);
```

Frame bodies, raw connection-state details, and errors are captured and
redacted by default. Use
`ISpectWSInterceptorSettingsBuilder.metadataOnly()` to retain frame lifecycle
metadata without payloads, or the production preset to disable sent/received
frame retention and keep redacted error diagnostics. `print*` fields shape
retained records but do not re-enable a suppressed frame. Use the concrete
settings `copyWith` or builder for retention controls. Builders provide
matching `with*` and `without*` methods for bodies, headers, and messages.

Balanced capture keeps typed frames and state objects useful through guarded,
bounded formatting before redaction. Set `captureMode` to
`DiagnosticCaptureMode.strict`, call `withStrictCapture()`, or use
`metadataOnly()`/`production()` when application-defined formatters must never
run.
Use `withResourceLimits(...)` for a WebSocket-local budget, or
`withInheritedResourceLimits()` to return to the logger policy.
Pass `inheritResourceLimits: true` to `copyWith` to clear an existing local
override. `NetworkInterceptorDefaults` is the shared source of truth used by
direct settings construction and every network settings builder;
`ISpectWSInterceptorDefaults` owns the WebSocket-only state and error-header
defaults.

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
