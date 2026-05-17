<!-- partial:header -->

`ispectify_ws` is a WebSocket interceptor for the [ISpect toolkit](#the-ispect-toolkit), built on the [`ws`](https://pub.dev/packages/ws) client. It captures every sent and received frame, surfaces connection lifecycle events, and redacts sensitive data before logging.

- Frame-level capture for sent and received messages.
- Error and close-event logging with stack traces.
- Same redaction engine as the HTTP interceptors.

## Install

```yaml
dependencies:
  ws: ^1.0.0
  ispectify: ^{{version}}
  ispectify_ws: ^{{version}}
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

<!-- partial:redaction -->

<!-- partial:install_matrix -->

<!-- partial:footer -->
