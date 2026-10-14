---
name: ispectify-ws-setup
description: >-
  Connect a consumer application's WebSocket client to ispectify_ws frame and lifecycle diagnostics using WsDiagnostics and WsDiagnosticsSink.
---

# WebSocket diagnostics setup

Add `ispectify` and `ispectify_ws` alongside the chosen client. The package
does not open sockets or export `ISpectWSInterceptor`; concrete client wrappers
belong in the consumer app.

## Integration

- Create `WsDiagnostics` per independently tracked connection using the shared
  app logger. Use `WsDiagnosticsSink` as the adapter port.
- Call `newConnection()` for each new session, including reconnects, to start
  a fresh correlation ID.
- Forward actual states, frames, and errors with `onStateChanged`, `onSent`,
  `onReceived`, and `onError`. Preserve client error handling and connection
  policy.
- Pass optional `messageId` on matching sent/received frames when the protocol
  provides it. Do not derive reply IDs from arbitrary frame contents.
- Cancel subscriptions and close sockets the app owns; diagnostics does not
  own these resources.

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

WsDiagnostics beginDiagnostics(ISpectLogger logger, String url) {
  final diagnostics = WsDiagnostics(
    logger: logger,
    settings: ISpectWSInterceptorSettingsBuilder.metadataOnly().build(),
  );
  diagnostics
    ..newConnection()
    ..onStateChanged(WsConnectionState.connecting, url: url);
  return diagnostics;
}

void recordReceived(WsDiagnosticsSink diagnostics, Object frame, String url) {
  diagnostics.onReceived(frame, url: url);
}
```

## Capture policy and verification

Use `--dart-define=ISPECT_ENABLED=true` for internal Flutter runs or
`dart run -DISPECT_ENABLED=true bin/main.dart` for Dart. Omit it from public
builds. Defaults capture bounded, redacted frames; metadata-only omits payloads
and uses strict capture. Keep `enableRedaction` on and avoid separate manual
logs containing protocol credentials or user content.

`logRequests` controls sent frames; `logResponses` controls received frames.
Settings on `WsDiagnostics` are immutable; prepare them before construction.
Omit local `resourceLimits` to inherit logger policy.

Verify states/errors, both frame directions, reply correlation when used,
a fresh ID after reconnect, and no capture without the define.
