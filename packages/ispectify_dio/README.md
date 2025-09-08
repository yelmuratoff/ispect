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

## Overview

> **ISpectify Dio** integrates the Dio HTTP client with the ISpectify logging system.

ISpectifyDio integrates the Dio HTTP client with the ISpectify logging system for HTTP request monitoring.

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
  ispectify_dio: ^4.3.3
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
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

// Use dart define to control ISpectify Dio integration
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
  final ISpectify iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
          logger: iSpectify,
    onInit: () {
      // Add ISpectify Dio interceptor only in development/staging
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
        appBar: AppBar(title: const Text('ISpectify Dio Example')),
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

## Advanced Configuration

### Production-Safe HTTP Logging

```dart
// Create a factory for conditional Dio setup
class DioFactory {
  static const bool _isEnabled = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
  
  static Dio createDio({
    String baseUrl = '',
    ISpectify? iSpectify,
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
void setupDioInterceptors(Dio dio, ISpectify? iSpectify) {
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