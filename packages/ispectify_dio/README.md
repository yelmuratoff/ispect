<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Dio HTTP client integration for ISpectLogger logging system</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_dio">
      <img src="https://img.shields.io/pub/v/ispectify_dio.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
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

## TL;DR

Capture Dio HTTP traffic with structured request/response/error logging.

## Interface Preview

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/panel.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/logs.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/detailed_http_request.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/detailed_http_response.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/inspector.png?raw=true" width="160" />
</div>

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/color_picker.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/cache.png?raw=true" width="160" />
</div>

## Live Web Demo

Try out ISpect in your browser! Visit [https://yelmuratoff.github.io/ispect/](https://yelmuratoff.github.io/ispect/) to drag and drop an ISpect log file and explore its contents interactively.

##  Architecture

ISpectLoggerDio integrates with the Dio HTTP client through interceptors:

| Component | Description |
|-----------|-----------|
| **Dio Interceptor** | Captures HTTP requests and responses |
| **Request Logger** | Logs request details (headers, body, params) |
| **Response Logger** | Logs response data and timing |
| **Error Handler** | Captures and logs HTTP errors |
| **Performance Tracker** | Measures request/response times |

## Overview

> **ISpectLogger Dio** integrates the Dio HTTP client with the ISpectLogger logging system.

ISpectLoggerDio integrates the Dio HTTP client with the ISpectLogger logging system for HTTP request monitoring.

### Key Features

- HTTP Request Logging: Automatic logging of all Dio requests
- Response Tracking: Detailed response logging with timing information
- Error Handling: Comprehensive error logging with stack traces
- Request Inspection: Headers, body, and parameter logging
- Sensitive Data Redaction: Centralized redaction for headers and bodies (enabled by default, configurable)
- Performance Metrics: Request/response timing and size tracking
- Configurable: Flexible configuration options for different environments

## Configuration Options

### Basic Setup

```dart
final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
  ),
);

// Initialize in ISpect.run onInit callback
ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    dio.interceptors.add(
      ISpectDioInterceptor(
        logger: iSpectify,
        settings: const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
        ),
      ),
    );
  },
);
```

### Sensitive Data Redaction

Redaction is enabled by default. Disable globally via settings or provide a custom redactor.

```dart
// Disable redaction
dio.interceptors.add(
  ISpectDioInterceptor(
    logger: iSpectify,
    settings: const ISpectDioInterceptorSettings(enableRedaction: false),
  ),
);

// Provide a custom redactor
final redactor = RedactionService();
redactor.ignoreKeys(['x-debug']);
redactor.ignoreValues(['sample-token']);

dio.interceptors.add(
  ISpectDioInterceptor(
    logger: iSpectify,
    redactor: redactor,
  ),
);
```

### Filtering with Optional Predicates

```dart
dio.interceptors.add(
  ISpectDioInterceptor(
    logger: iSpectify,
    settings: const ISpectDioInterceptorSettings(
      printRequestHeaders: true,
      // requestFilter: (requestOptions) =>
      //     requestOptions.path != '/sensitive-endpoint',
      // responseFilter: (response) => response.statusCode != 404,
      // errorFilter: (error) => error.response?.statusCode != 404,
    ),
  ),
);
```

### Multiple Dio Instances

```dart
final Dio mainDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
final Dio uploadDio = Dio(BaseOptions(baseUrl: 'https://upload.example.com'));

mainDio.interceptors.add(ISpectDioInterceptor(logger: iSpectify));
uploadDio.interceptors.add(ISpectDioInterceptor(logger: iSpectify));
```

## Installation

Add ispectify_dio to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_dio: ^4.4.8-dev01
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

</details>

## 🚀 Quick Start

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

// Use dart define to control ISpectLogger Dio integration
const bool kEnableISpectDio = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

void main() {
  if (kEnableISpectDio) {
    _initializeWithISpect();
  } else {
    // Production initialization without ISpect
    runApp(MyApp());
  }
}

void _initializeWithISpect() {
  final ISpectLogger iSpectify = ISpectFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
          logger: iSpectify,
    onInit: () {
      // Add ISpectLogger Dio interceptor only in development/staging
      dio.interceptors.add(
        ISpectDioInterceptor(
          logger: iSpectify,
          settings: const ISpectDioInterceptorSettings(
            printRequestHeaders: true,
          ),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpectLogger Dio Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // HTTP requests will be logged only when ISpect is enabled
                  dio.get<dynamic>('/posts/1');
                },
                child: const Text('Send GET Request'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Error requests are also logged (when enabled)
                  dio.get<dynamic>('/invalid-endpoint');
                },
                child: const Text('Send Error Request'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Upload file with FormData
                  final FormData formData = FormData();
                  formData.files.add(MapEntry(
                    'file',
                    MultipartFile.fromBytes(
                      [1, 2, 3],
                      filename: 'file.txt',
                    ),
                  ));
                  dio.post<dynamic>('/upload', data: formData);
                },
                child: const Text('Upload File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Minimal Setup

## Advanced Configuration

### Production-Safe HTTP Logging

```dart
// Create a factory for conditional Dio setup
class DioFactory {
  static const bool _isEnabled = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
  
  static Dio createDio({
    String baseUrl = '',
    ISpectLogger? iSpectify,
  }) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    
    // Only add interceptor when ISpect is enabled
    if (_isEnabled && iSpectify != null) {
      dio.interceptors.add(
        ISpectDioInterceptor(
          logger: iSpectify,
          settings: ISpectDioInterceptorSettings(
            printRequestHeaders: kDebugMode,
            enableRedaction: true, // Keep redaction enabled outside development
          ),
        ),
      );
    }
    
    return dio;
  }
}

// Usage
final dio = DioFactory.createDio(
  baseUrl: 'https://api.example.com',
  iSpectify: ISpect.logger,
);
```

### Environment-Specific Configuration

```dart
class DioConfig {
  static ISpectDioInterceptorSettings getSettings() {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'development':
        return const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          enableRedaction: false, // Only disable if using non-sensitive test data
        );
      case 'staging':
        return const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: false,
          enableRedaction: true,
        );
      default: // production
        return const ISpectDioInterceptorSettings(
          printRequestHeaders: false,
          printResponseHeaders: false,
          enableRedaction: true,
        );
    }
  }
}
```

### Conditional Interceptor Setup

```dart
void setupDioInterceptors(Dio dio, ISpectLogger? iSpectify) {
  const isISpectEnabled = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
  
  if (isISpectEnabled && iSpectify != null) {
    // Custom redactor for sensitive data
    final redactor = RedactionService();
    redactor.ignoreKeys(['authorization', 'x-api-key']);
    redactor.ignoreValues(['<placeholder-secret>', '<another-placeholder>']);
    
    dio.interceptors.add(
      ISpectDioInterceptor(
        logger: iSpectify,
        redactor: redactor,
        settings: DioConfig.getSettings(),
      ),
    );
  }
  
  // Add other production interceptors here (avoid duplicate logging)
}
```

## Examples

See the [example/](example/) directory for complete integration examples with different Dio configurations.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispectify](../ispectify) - Foundation logging system
- [ispectify_http](../ispectify_http) - Standard HTTP client integration
- [ispect](../ispect) - Main debugging interface
- [dio](https://pub.dev/packages/dio) - HTTP client for Dart

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>