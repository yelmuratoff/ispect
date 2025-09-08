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

Redaction is enabled by default. Disable globally via settings or provide a custom redactor.

```dart
// Disable redaction
final interceptor = ISpectWSInterceptor(
  logger: logger,
  settings: const ISpectWSInterceptorSettings(enableRedaction: false),
);

// Provide a custom redactor
final redactor = RedactionService();
redactor.ignoreKeys(['x-debug']);
redactor.ignoreValues(['sample-token']);
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
    sentFilter: (request) {
      return request.body?['data']?.toString().contains('important') ?? false;
    },
    receivedFilter: (response) {
      return !response.body?['data']?.toString().contains('error') ?? true;
    },
    errorFilter: (error) {
      return true;
    },
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
  ispectify_ws: ^4.3.3
```

## Security & Production Guidelines

> IMPORTANT: ISpect is a debugging tool and should NEVER be included in production builds

### Production Safety

ISpect contains sensitive debugging information and should only be used in development and staging environments. To ensure ISpect is completely removed from production builds, use the following approach:

### Recommended Setup with Dart Define Constants

**1. Create environment-aware initialization:**

```dart
// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Use dart define to control ISpect inclusion
const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  if (kEnableISpect) {
    // Initialize ISpect only in development/staging
    _initializeISpect();
  } else {
    // Production initialization without ISpect
    runApp(MyApp());
  }
}

void _initializeISpect() {
  // ISpect initialization code here
  // This entire function will be tree-shaken in production
}
```

**2. Build Commands:**

```bash
# Development build (includes ISpect)
flutter run --dart-define=ENABLE_ISPECT=true

# Staging build (includes ISpect)
flutter build appbundle --dart-define=ENABLE_ISPECT=true

# Production build (ISpect completely removed via tree-shaking)
flutter build appbundle --dart-define=ENABLE_ISPECT=false
# or simply:
flutter build appbundle  # defaults to false
```

**3. Conditional Widget Wrapping:**

```dart
Widget build(BuildContext context) {
  return MaterialApp(
    // Conditionally add ISpectBuilder in MaterialApp builder
    builder: (context, child) {
      if (kEnableISpect) {
        return ISpectBuilder(child: child ?? const SizedBox.shrink());
      }
      return child ?? const SizedBox.shrink();
    },
    home: Scaffold(/* your app content */),
  );
}
```

### Security Benefits

- Zero Production Footprint: Tree-shaking removes all ISpect code from release builds
- No Sensitive Data Exposure: Debug information never reaches production users
- Performance Optimized: No debugging overhead in production
- Compliance Ready: Meets security requirements for app store releases

### 🔍 Verification

To verify ISpect is not included in your production build:

```bash
# Build release APK and check size difference
flutter build apk --dart-define=ENABLE_ISPECT=false --release
flutter build apk --dart-define=ENABLE_ISPECT=true --release

# Use flutter tools to analyze bundle
flutter analyze --dart-define=ENABLE_ISPECT=false
```

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
  const url = 'wss://echo.websocket.org';
  
  if (kEnableISpectWS) {
    _initializeWithISpect(url);
  } else {
    // Production initialization without ISpect
    _initializeWithoutISpect(url);
  }
}

void _initializeWithISpect(String url) {
  final logger = ISpectify();

  // Create WebSocket interceptor only in development/staging
  final interceptor = ISpectWSInterceptor(
    logger: logger,
    settings: const ISpectWSInterceptorSettings(
      enabled: true,
      printSentData: true,
      printReceivedData: true,
      printErrorData: true,
      enableRedaction: true, // Always enable redaction for security
    ),
  );

  // Create WebSocket client with interceptor
  final client = WebSocketClient(
    WebSocketOptions.common(
      connectionRetryInterval: (
        min: const Duration(milliseconds: 500),
        max: const Duration(seconds: 15),
      ),
      interceptors: [interceptor],
    ),
  );

  // Set client for interceptor
  interceptor.setClient(client);

  _runWebSocketExample(client);
}

void _initializeWithoutISpect(String url) {
  // Create WebSocket client without interceptor for production
  final client = WebSocketClient(
    WebSocketOptions.common(
      connectionRetryInterval: (
        min: const Duration(milliseconds: 500),
        max: const Duration(seconds: 15),
      ),
    ),
  );

  _runWebSocketExample(client);
}

void _runWebSocketExample(WebSocketClient client) {
  const url = 'wss://echo.websocket.org';
  
  // Connect and send messages - logged only when ISpect is enabled
  client
    ..connect(url)
    ..add('Hello WebSocket!')
    ..add('{"type": "message", "data": "JSON data"}');

  // Listen to messages
  client.stream.listen(
    (message) {
      print('Received: $message');
    },
    onError: (error) {
      print('Error: $error');
    },
  );

  // Close connection after some time
  Timer(const Duration(seconds: 5), () async {
    await client.close();
    print('Connection closed');
    if (kEnableISpectWS) {
      print('Metrics: ${client.metrics}');
    }
  });
}
```

## Examples

See the [example/](example/) directory for complete integration examples with different WebSocket client configurations.

## 🏗️ Architecture

ISpectifyWS integrates with the WebSocket client through interceptors:

| Component | Description |
|-----------|-----------|
| **WS Interceptor** | Captures WebSocket connection events and messages |
| **Message Logger** | Logs sent and received message details |
| **Connection Logger** | Logs connection state and URL information |
| **Error Handler** | Captures and logs WebSocket errors |
| **Metrics Tracker** | Measures connection timing and message counts |

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