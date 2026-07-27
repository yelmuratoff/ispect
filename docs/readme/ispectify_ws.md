<!-- partial:header -->

`ispectify_ws` is the provider-agnostic WebSocket diagnostics layer for the [ISpect toolkit](#the-ispect-toolkit). It captures sent and received frames, connection-state transitions, and errors — for **any** WebSocket client — and redacts sensitive data before logging. The published package depends only on `ispectify`; you keep your own WebSocket client dependency.

- Frame-level capture for sent and received messages (`ws-sent` / `ws-received`).
- Connection lifecycle logging via `ws-state` (connecting / open / closing / closed / reconnecting).
- Error logging with stack traces (`ws-error`); one correlation id per connection session.
- Same redaction engine as the HTTP interceptors.

## Install

```yaml
dependencies:
  ispectify: ^{{version}}
  ispectify_ws: ^{{version}}
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
);

final diagnostics = WsDiagnostics(logger: ISpect.logger, settings: settings);
```

Frame bodies and raw connection-state details are omitted by default. The
explicit development builder preset enables verbose sent/received/state
payload capture while keeping redaction on. The
production preset disables sent/received frame retention and keeps redacted
error diagnostics. `print*` fields shape retained records but do not re-enable
a suppressed frame. Use the concrete settings `copyWith` or builder for
retention controls; the shared base `configure` helper retains its
legacy-compatible field set.

<!-- partial:redaction -->

<!-- partial:install_matrix -->

<!-- partial:footer -->
