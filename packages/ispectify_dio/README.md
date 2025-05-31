<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Dio HTTP client integration for ISpectify logging system</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_dio">
      <img src="https://img.shields.io/pub/v/ispectify_dio.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_dio/score">
      <img src="https://img.shields.io/pub/likes/ispectify_dio?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_dio/score">
      <img src="https://img.shields.io/pub/points/ispectify_dio?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **ISpectify Dio** provides seamless integration between Dio HTTP client and the ISpectify logging system.

<div align="center">

🌐 **HTTP Logging** • 📊 **Response Tracking** • ❌ **Error Handling** • ⚡ **Performance**

</div>

Streamline your HTTP debugging workflow by automatically capturing and logging all Dio HTTP client interactions. Perfect for monitoring API calls, debugging network issues, and tracking performance metrics.

### 🎯 Key Features

- 🌐 **HTTP Request Logging**: Automatic logging of all Dio requests
- 📊 **Response Tracking**: Detailed response logging with timing information
- ❌ **Error Handling**: Comprehensive error logging with stack traces
- 🔍 **Request Inspection**: Headers, body, and parameter logging
- ⚡ **Performance Metrics**: Request/response timing and size tracking
- 🎛️ **Configurable**: Flexible configuration options for different environments

## 🔧 Configuration Options

### Basic Configuration

```dart
final interceptor = ISpectifyDioInterceptor(
  ispectify: ispectify,
  settings: ISpectifyDioSettings(
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
);
```

### Advanced Filtering

```dart
final interceptor = ISpectifyDioInterceptor(
  ispectify: ispectify,
  settings: ISpectifyDioSettings(
    // Filter sensitive headers
    headerFilter: (headers) => headers..remove('Authorization'),
    
    // Filter request bodies
    requestBodyFilter: (body) {
      if (body is Map) {
        return Map.from(body)..remove('password');
      }
      return body;
    },
    
    // Custom log levels
    requestLogLevel: LogLevel.debug,
    responseLogLevel: LogLevel.info,
    errorLogLevel: LogLevel.error,
  ),
);
```

## 📦 Installation

Add ispectify_dio to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_dio: ^4.1.3-dev13
```

## 🚀 Quick Start

```dart
import 'package:dio/dio.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  final ispectify = ISpectify();
  
  // Create Dio instance with ISpectify interceptor
  final dio = Dio()
    ..interceptors.add(
      ISpectifyDioInterceptor(
        ispectify: ispectify,
        settings: ISpectifyDioSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestBody: true,
          printResponseBody: true,
        ),
      ),
    );
  
  // All HTTP requests will be automatically logged
  final response = await dio.get('https://api.example.com/data');
}
```

## ⚙️ Advanced Features

### Custom Log Formatting

```dart
final interceptor = ISpectifyDioInterceptor(
  ispectify: ispectify,
  settings: ISpectifyDioSettings(
    requestFormatter: (request) => 'API Call: ${request.method} ${request.uri}',
    responseFormatter: (response) => 'Response: ${response.statusCode} (${response.data?.length ?? 0} bytes)',
  ),
);
```

### Environment-based Configuration

```dart
final interceptor = ISpectifyDioInterceptor(
  ispectify: ispectify,
  settings: kDebugMode 
    ? ISpectifyDioSettings.debug() // Full logging in debug
    : ISpectifyDioSettings.production(), // Minimal logging in production
);
```

### Multiple Dio Instances

```dart
// API client
final apiDio = Dio()
  ..interceptors.add(
    ISpectifyDioInterceptor(
      ispectify: ispectify,
      tag: 'API',
    ),
  );

// Analytics client
final analyticsDio = Dio()
  ..interceptors.add(
    ISpectifyDioInterceptor(
      ispectify: ispectify,
      tag: 'Analytics',
    ),
  );
```

## 📚 Examples

See the [example/](example/) directory for complete integration examples with different Dio configurations.

## 🏗️ Architecture

ISpectifyDio integrates with the Dio HTTP client through interceptors:

| Component | Description |
|-----------|-----------|
| **Dio Interceptor** | Captures HTTP requests and responses |
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
- [ispectify_http](../ispectify_http) - Standard HTTP client integration
- [ispect](../ispect) - Main debugging interface
- [dio](https://pub.dev/packages/dio) - HTTP client for Dart

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>