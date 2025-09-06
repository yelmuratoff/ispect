<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>HTTP interceptor integration for ISpectify logging system using http_interceptor package</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_http">
      <img src="https://img.shields.io/pub/v/ispectify_http.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
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

> **ISpectify HTTP** provides seamless integration between the http_interceptor package and the ISpectify logging system.

<div align="center">

🌐 **HTTP Logging** • 📊 **Response Tracking** • ❌ **Error Handling** • ⚡ **Performance**

</div>

Enhance your HTTP debugging workflow by automatically capturing and logging all HTTP client interactions using the http_interceptor package. Provides seamless integration with Dart's HTTP package through interceptors for comprehensive request and response monitoring.

### 🎯 Key Features

- 🌐 **HTTP Request Logging**: Automatic logging of all HTTP requests
- 📊 **Response Tracking**: Detailed response logging with timing information
- ❌ **Error Handling**: Comprehensive error logging with stack traces
- 🔍 **Request Inspection**: Headers, body, and parameter logging
- 🔒 **Sensitive Data Redaction**: Centralized redaction for headers and bodies (enabled by default, configurable)
- ⚡ **Performance Metrics**: Request/response timing and size tracking
- 🎛️ **Lightweight**: Minimal overhead using http_interceptor package

## 🔧 Configuration Options

### Basic Setup

```dart
final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    client.interceptors.add(
      ISpectHttpInterceptor(iSpectify: iSpectify),
    );
  },
);
```

### Sensitive Data Redaction

Redaction is enabled by default. Disable globally via settings or provide a custom redactor.

```dart
// Disable redaction
client.interceptors.add(
  ISpectHttpInterceptor(
    iSpectify: iSpectify,
    settings: const ISpectHttpInterceptorSettings(enableRedaction: false),
  ),
);

// Provide a custom redactor
final redactor = RedactionService();
redactor.ignoreKeys(['x-debug']);
redactor.ignoreValues(['sample-token']);

client.interceptors.add(
  ISpectHttpInterceptor(
    iSpectify: iSpectify,
    redactor: redactor,
  ),
);
```

### File Upload Example

```dart
final List<int> bytes = [1, 2, 3];
const String filename = 'file.txt';

final http_interceptor.MultipartRequest request = http_interceptor.MultipartRequest(
  'POST',
  Uri.parse('https://api.example.com/upload'),
);

request.files.add(http_interceptor.MultipartFile.fromBytes(
  'file',
  bytes,
  filename: filename,
));

client.send(request);
```

## 📦 Installation

Add ispectify_http to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_http: ^4.3.2
```

## ⚠️ Security & Production Guidelines

> **🚨 IMPORTANT: ISpect is a debugging tool and should NEVER be included in production builds**

### 🔒 Production Safety

ISpect contains sensitive debugging information and should only be used in development and staging environments. To ensure ISpect is completely removed from production builds, use the following approach:

### ✅ Recommended Setup with Dart Define Constants

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

### 🛡️ Security Benefits

- ✅ **Zero Production Footprint**: Tree-shaking removes all ISpect code from release builds
- ✅ **No Sensitive Data Exposure**: Debug information never reaches production users
- ✅ **Performance Optimized**: No debugging overhead in production
- ✅ **Compliance Ready**: Meets security requirements for app store releases

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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

// Use dart define to control ISpectify HTTP integration
const bool kEnableISpectHttp = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

void main() {
  if (kEnableISpectHttp) {
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
      // Add ISpectify HTTP interceptor only in development/staging
      client.interceptors.add(
        ISpectHttpInterceptor(
          iSpectify: iSpectify,
          settings: const ISpectHttpInterceptorSettings(
            enableRedaction: true, // Always enable redaction for security
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
        appBar: AppBar(title: const Text('ISpectify HTTP Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // HTTP requests will be logged only when ISpect is enabled
                  await client.get(
                    Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
                  );
                },
                child: const Text('Send HTTP Request'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Error requests are also logged (when enabled)
                  await client.get(
                    Uri.parse('https://jsonplaceholder.typicode.com/invalid'),
                  );
                },
                child: const Text('Send Error Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## ⚙️ Advanced Configuration

### 🛡️ Production-Safe HTTP Client Setup

```dart
// Create a factory for conditional HTTP client setup
class HttpClientFactory {
  static const bool _isEnabled = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
  
  static http_interceptor.InterceptedClient createClient({
    ISpectify? iSpectify,
  }) {
    final List<http_interceptor.InterceptorContract> interceptors = [];
    
    // Only add ISpect interceptor when enabled
    if (_isEnabled && iSpectify != null) {
      interceptors.add(
        ISpectHttpInterceptor(
          iSpectify: iSpectify,
          settings: const ISpectHttpInterceptorSettings(
            enableRedaction: true, // Always enable redaction for security
          ),
        ),
      );
    }
    
    return http_interceptor.InterceptedClient.build(
      interceptors: interceptors,
    );
  }
}

// Usage
final client = HttpClientFactory.createClient(
  iSpectify: ISpect.logger,
);
```

### 🔒 Environment-Specific Configuration

```dart
class HttpConfig {
  static ISpectHttpInterceptorSettings getSettings() {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'development':
        return const ISpectHttpInterceptorSettings(
          enableRedaction: false, // Allow full debugging in dev
        );
      case 'staging':
        return const ISpectHttpInterceptorSettings(
          enableRedaction: true, // Enable redaction in staging
        );
      default: // production
        return const ISpectHttpInterceptorSettings(
          enableRedaction: true,
        );
    }
  }
}
```

### 🎛️ Conditional Interceptor Setup

```dart
void setupHttpInterceptors(
  http_interceptor.InterceptedClient client,
  ISpectify? iSpectify,
) {
  const isISpectEnabled = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
  
  if (isISpectEnabled && iSpectify != null) {
    // Custom redactor for sensitive data
    final redactor = RedactionService();
    redactor.ignoreKeys(['authorization', 'x-api-key']);
    redactor.ignoreValues(['password', 'token']);
    
    client.interceptors.add(
      ISpectHttpInterceptor(
        iSpectify: iSpectify,
        redactor: redactor,
        settings: HttpConfig.getSettings(),
      ),
    );
  }
  
  // Add other production interceptors here
}
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
- [http_interceptor](https://pub.dev/packages/http_interceptor) - HTTP interceptor package for Dart

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>