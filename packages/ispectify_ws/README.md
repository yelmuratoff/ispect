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
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
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

## 🔍 Overview

> **ISpectify WebSocket** provides seamless integration between the ws package and the ISpectify logging system for comprehensive WebSocket monitoring.

<div align="center">

🔗 **WebSocket Logging** • � **Message Tracking** • ❌ **Error Handling** • ⚡ **Performance**

</div>

Enhance your WebSocket debugging workflow by automatically capturing and logging all WebSocket client interactions using the ws package. Provides seamless integration with Dart's WebSocket client through interceptors for comprehensive connection and message monitoring.

### 🎯 Key Features

- 🔗 **WebSocket Connection Logging**: Automatic logging of all WebSocket connections
- � **Message Tracking**: Detailed logging of sent and received messages
- ❌ **Error Handling**: Comprehensive error logging with stack traces
- 🔍 **Connection Inspection**: URL, connection state, and metrics logging
- ⚡ **Performance Metrics**: Connection timing and message count tracking
- 🎛️ **Lightweight**: Minimal overhead using ws package interceptors

## 🔧 Configuration Options

### Basic Setup

```dart
final logger = ISpectify();

// Create interceptor with custom settings
final interceptor = ISpectWSInterceptor(
  url: 'wss://echo.websocket.org',
  logger: logger,
  settings: const ISpectWSInterceptorSettings(
    enabled: true,
    printRequestData: true,
    printResponseData: true,
    printErrorData: true,
    printRequestHeaders: false,
  ),
);

// Create WebSocket client
final client = WebSocketClient(
  WebSocketOptions.common(
    interceptors: [interceptor],
  ),
);

// Set client for interceptor
interceptor.setClient(client);
```

### Advanced Configuration with Filters

```dart
final interceptor = ISpectWSInterceptor(
  url: url,
  logger: logger,
  settings: ISpectWSInterceptorSettings(
    enabled: true,
    // Custom filters for selective logging
    requestFilter: (request) {
      // Only log requests containing specific data
      return request.body?['data']?.toString().contains('important') ?? false;
    },
    responseFilter: (response) {
      // Only log successful responses
      return !response.body?['data']?.toString().contains('error') ?? true;
    },
    errorFilter: (error) {
      // Log all errors
      return true;
    },
    // Custom console colors
    requestPen: AnsiPen()..blue(),
    responsePen: AnsiPen()..green(),
    errorPen: AnsiPen()..red(),
  ),
);
```

### Connection Event Handling

```dart
final interceptor = ISpectWSInterceptor(
  url: url,
  logger: logger,
  onClientReady: (client) {
    print('WebSocket client is ready');
    print('Client metrics: ${client.metrics}');
  },
);
```

## 📦 Installation

Add ispectify_ws to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_ws: ^4.2.1-dev07
```

## 🚀 Quick Start

```dart
import 'dart:async';
import 'dart:io' as io show exit;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

void main() {
  const url = 'wss://echo.websocket.org';
  final logger = ISpectify();

  // Create WebSocket interceptor
  final interceptor = ISpectWSInterceptor(
    url: url,
    logger: logger,
    settings: const ISpectWSInterceptorSettings(
      enabled: true,
      printRequestData: true,
      printResponseData: true,
      printErrorData: true,
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

  // Connect and send messages - all will be automatically logged
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
    print('Metrics: ${client.metrics}');
  });
}
```

## 📚 Examples

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

## 🔗 Related Packages

- [ispectify](../ispectify) - Foundation logging system
- [ispectify_dio](../ispectify_dio) - Dio HTTP client integration
- [ispectify_http](../ispectify_http) - HTTP client integration
- [ispect](../ispect) - Main debugging interface
- [ws](https://pub.dev/packages/ws) - WebSocket client package for Dart

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>