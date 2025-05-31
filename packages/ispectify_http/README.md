<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispectify_http.png?raw=true" width="400">
  
  <p><strong>Standard HTTP client integration for ISpectify logging system</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_http">
      <img src="https://img.shields.io/pub/v/ispectify_http.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_http/score">
      <img src="https://img.shields.io/pub/likes/ispectify_http?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_http/score">
      <img src="https://img.shields.io/pub/points/ispectify_http?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **ISpectify HTTP** provides seamless integration between Dart's standard HTTP client and the ISpectify logging system.

<div align="center">

🌐 **HTTP Logging** • 📊 **Response Tracking** • ❌ **Error Handling** • ⚡ **Performance**

</div>

Enhance your HTTP debugging workflow by automatically capturing and logging all standard HTTP client interactions. Ideal for applications using Dart's built-in HTTP client or when you need a lightweight HTTP logging solution.

### 🎯 Key Features

- 🌐 **HTTP Request Logging**: Automatic logging of all HTTP requests
- 📊 **Response Tracking**: Detailed response logging with timing information
- ❌ **Error Handling**: Comprehensive error logging with stack traces
- 🔍 **Request Inspection**: Headers, body, and parameter logging
- ⚡ **Performance Metrics**: Request/response timing and size tracking
- 🎛️ **Lightweight**: Minimal overhead with the standard HTTP client

## 🔧 Configuration Options

### Basic Configuration

```dart
final client = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpInterceptor(
      ispectify: ispectify,
      settings: ISpectifyHttpSettings(
        // Request logging
        printRequestHeaders: true,
        printRequestBody: true,
        
        // Response logging
        printResponseHeaders: true,
        printResponseBody: true,
        
        // Error handling
        printErrorDetails: true,
        
        // Performance
        trackRequestTime: true,
      ),
    ),
  ],
);
```

### Advanced Filtering

```dart
final client = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpInterceptor(
      ispectify: ispectify,
      settings: ISpectifyHttpSettings(
        // Filter sensitive headers
        headerFilter: (headers) => Map.from(headers)
          ..remove('authorization'),
        
        // Filter request bodies
        requestBodyFilter: (body) {
          if (body.contains('password')) {
            return body.replaceAll(RegExp(r'"password":"[^"]*"'), '"password":"***"');
          }
          return body;
        },
        
        // Custom log levels
        requestLogLevel: LogLevel.debug,
        responseLogLevel: LogLevel.info,
        errorLogLevel: LogLevel.error,
      ),
    ),
  ],
);
```

## 📦 Installation

Add ispectify_http to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_http: ^4.1.3
```

## 🚀 Quick Start

```dart
import 'package:http/http.dart' as http;
import 'package:ispectify_http/ispectify_http.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  final ispectify = ISpectify();
  
  // Create HTTP client with ISpectify interceptor
  final client = InterceptedClient.build(
    interceptors: [
      ISpectifyHttpInterceptor(
        ispectify: ispectify,
        settings: ISpectifyHttpSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestBody: true,
          printResponseBody: true,
        ),
      ),
    ],
  );
  
  // All HTTP requests will be automatically logged
  final response = await client.get(
    Uri.parse('https://api.example.com/data'),
  );
  
  // Don't forget to close the client
  client.close();
}
```

## ⚙️ Advanced Features

### Custom Log Formatting

```dart
final client = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpInterceptor(
      ispectify: ispectify,
      settings: ISpectifyHttpSettings(
        requestFormatter: (request) => 'HTTP ${request.method} ${request.url}',
        responseFormatter: (response) => 'Response ${response.statusCode} (${response.body.length} bytes)',
      ),
    ),
  ],
);
```

### Environment-based Configuration

```dart
final client = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpInterceptor(
      ispectify: ispectify,
      settings: kDebugMode 
        ? ISpectifyHttpSettings.debug() // Full logging in debug
        : ISpectifyHttpSettings.production(), // Minimal logging in production
    ),
  ],
);
```

### Multiple HTTP Clients

```dart
// API client
final apiClient = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpInterceptor(
      ispectify: ispectify,
      tag: 'API',
    ),
  ],
);

// Analytics client
final analyticsClient = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpInterceptor(
      ispectify: ispectify,
      tag: 'Analytics',
    ),
  ],
);
```

## 📚 Examples

See the [example/](example/) directory for complete integration examples with different HTTP client configurations.

## 🏗️ Architecture

ISpectifyHttp integrates with the standard HTTP client through interceptors:

| Component | Description |
|-----------|-----------|
| **HTTP Interceptor** | Captures HTTP requests and responses |
| **Request Logger** | Logs request details (headers, body, params) |
| **Response Logger** | Logs response data and timing |
| **Error Handler** | Captures and logs HTTP errors |
| **Performance Tracker** | Measures request/response times |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [ispectify](../ispectify) - Foundation logging system
- [ispectify_dio](../ispectify_dio) - Dio HTTP client integration
- [ispect](../ispect) - Main debugging interface
- [http](https://pub.dev/packages/http) - Standard HTTP client for Dart

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>