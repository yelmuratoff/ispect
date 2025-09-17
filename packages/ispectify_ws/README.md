<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>WebSocket interceptor integration for ISpectify logging system using ws package</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_ws">
      <img src="https://img.shields.io/pub/v/ispectify_ws.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_ws/score">
      <img src="https://img.shields.io/pub/likes/ispectify_ws?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_ws/score">
      <img src="https://img.shields.io/pub/points/ispectify_ws?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## TL;DR

Track WebSocket connects, messages, errors, metrics with optional redaction.

## 🏗️ Architecture

ISpectifyWS integrates with the WebSocket client through interceptors:

| Component | Description |
|-----------|-----------|
| **WS Interceptor** | Captures WebSocket connection events and messages |
| **Message Logger** | Logs sent and received message details |
| **Connection Logger** | Logs connection state and URL information |
| **Error Handler** | Captures and logs WebSocket errors |
| **Metrics Tracker** | Measures connection timing and message counts |

## Overview

> **ISpectify WebSocket** integrates the ws package with the ISpectify logging system for WebSocket monitoring.

ISpectifyWS integrates the ws package with the ISpectify logging system for WebSocket monitoring.

### Key Features

- WebSocket Connection Logging: Automatic logging of all WebSocket connections
- Message Tracking: Detailed logging of sent and received messages
- Error Handling: Comprehensive error logging with stack traces
- Connection Inspection: URL, connection state, and metrics logging
- Sensitive Data Redaction: Centralized redaction for sent/received payloads (enabled by default, configurable)
- Performance Metrics: Connection timing and message count tracking
- Lightweight: Minimal overhead using ws package interceptors

## Configuration Options

### Basic Setup

```dart
final logger = ISpectify();

final interceptor = ISpectWSInterceptor(
  logger: logger,
  settings: const ISpectWSInterceptorSettings(
    enabled: true,
    printSentData: true,
    printReceivedData: true,
    printReceivedMessage: true,
    printErrorData: true,
    printErrorMessage: true,
    printReceivedHeaders: false,
  ),
);

final client = WebSocketClient(
  WebSocketOptions.common(
    interceptors: [interceptor],
  ),
);

interceptor.setClient(client);
```

### Sensitive Data Redaction

Redaction is enabled by default. Disable only with synthetic / non-sensitive data.

```dart
final interceptor = ISpectWSInterceptor(
  logger: logger,
  settings: const ISpectWSInterceptorSettings(enableRedaction: false),
);

final redactor = RedactionService();
redactor.ignoreKeys(['x-debug']);
redactor.ignoreValues(['<placeholder-token>']);
final interceptor2 = ISpectWSInterceptor(
  logger: logger,
  redactor: redactor,
);
```

### Filtering with Optional Predicates

```dart
final interceptor = ISpectWSInterceptor(
  logger: logger,
  settings: ISpectWSInterceptorSettings(
    enabled: true,
    sentFilter: (request) => request.body?['data']?.toString().contains('important') ?? false,
    receivedFilter: (response) => !(response.body?['data']?.toString().contains('error') ?? false),
    errorFilter: (error) => true,
    sentPen: AnsiPen()..blue(),
    receivedPen: AnsiPen()..green(),
    errorPen: AnsiPen()..red(),
  ),
);
```

### Connection Event Handling

```dart
final interceptor = ISpectWSInterceptor(
  logger: logger,
  onClientReady: (client) {
    print('WebSocket client is ready');
    print('Client metrics: ${client.metrics}');
  },
);
```

## Installation

Add ispectify_ws to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_ws: ^4.4.0-dev04
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

</details>

## 🚀 Quick Start

```dart
import 'dart:async';
import 'dart:io' as io show exit;
import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

// Use dart define to control ISpectify WebSocket integration
const bool kEnableISpectWS = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  // Replace with your test endpoint or local dev server; avoid deprecated public echo services
  const url = 'wss://example.com/socket';
  if (kEnableISpectWS) {
    _initializeWithISpect(url);
  } else {
    _initializeWithoutISpect(url);
  }
}

void _initializeWithISpect(String url) {
  final logger = ISpectify();
  final interceptor = ISpectWSInterceptor(
    logger: logger,
    settings: const ISpectWSInterceptorSettings(
      enabled: true,
      printSentData: true,
      printReceivedData: true,
      printErrorData: true,
      enableRedaction: true, // Keep redaction enabled for any non-local traffic
    ),
  );
  final client = WebSocketClient(
    WebSocketOptions.common(
      connectionRetryInterval: (
        min: const Duration(milliseconds: 500),
        max: const Duration(seconds: 15),
      ),
      interceptors: [interceptor],
    ),
  );
  interceptor.setClient(client);
  _runWebSocketExample(client, url);
}

void _initializeWithoutISpect(String url) {
  final client = WebSocketClient(
    WebSocketOptions.common(
      connectionRetryInterval: (
        min: const Duration(milliseconds: 500),
        max: const Duration(seconds: 15),
      ),
    ),
  );
  _runWebSocketExample(client, url);
}

void _runWebSocketExample(WebSocketClient client, String url) {
  client
    ..connect(url)
    ..add('Hello WebSocket!');
  client.stream.listen(
    (message) {
      print('Received: $message');
    },
    onError: (error) {
      print('Error: $error');
    },
  );
  Timer(const Duration(seconds: 5), () async {
    await client.close();
    print('Connection closed');
    if (kEnableISpectWS) {
      print('Metrics: ${client.metrics}');
    }
  });
}
```

### Minimal Setup

## Examples

See the [example/](example/) directory for complete integration examples with different WebSocket client configurations.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispectify](../ispectify) - Foundation logging system
- [ispectify_dio](../ispectify_dio) - Dio HTTP client integration
- [ispectify_http](../ispectify_http) - HTTP client integration
- [ispect](../ispect) - Main debugging interface
- [ws](https://pub.dev/packages/ws) - WebSocket client package for Dart

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>