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

## TL;DR

Monitor standard HTTP client requests/responses with redaction & timing.

## 🏗️ Architecture

ISpectifyHttp integrates with the standard HTTP client through interceptors:

| Component | Description |
|-----------|-----------|
| **HTTP Interceptor** | Captures HTTP requests and responses |
| **Request Logger** | Logs request details (headers, body, params) |
| **Response Logger** | Logs response data and timing |
| **Error Handler** | Captures and logs HTTP errors |
| **Performance Tracker** | Measures request/response times |

## Overview

> **ISpectify HTTP** integrates the http_interceptor package with the ISpectify logging system.

ISpectifyHttp integrates the http_interceptor package with the ISpectify logging system for HTTP request monitoring.

### Key Features

- HTTP Request Logging: Automatic logging of all HTTP requests
- Response Tracking: Detailed response logging with timing information
- Error Handling: Comprehensive error logging with stack traces
- Request Inspection: Headers, body, and parameter logging
- Sensitive Data Redaction: Centralized redaction for headers and bodies (enabled by default, configurable)
- Performance Metrics: Request/response timing and size tracking
- Lightweight: Minimal overhead using http_interceptor package

## Configuration Options

### Basic Setup

```dart
final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    client.interceptors.add(
      ISpectHttpInterceptor(logger: iSpectify),
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
    logger: iSpectify,
    settings: const ISpectHttpInterceptorSettings(enableRedaction: false),
  ),
);

// Provide a custom redactor
final redactor = RedactionService();
redactor.ignoreKeys(['x-debug']);
redactor.ignoreValues(['sample-token']);

client.interceptors.add(
  ISpectHttpInterceptor(
    logger: iSpectify,
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

## Installation

Add ispectify_http to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_http: ^4.4.0-dev08
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

</details>

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
          logger: iSpectify,
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

### Minimal Setup

## Advanced Configuration

### Production-Safe HTTP Client Setup

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
          logger: iSpectify,
          settings: const ISpectHttpInterceptorSettings(
            enableRedaction: true,
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

### Environment-Specific Configuration

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
          enableRedaction: true,
        );
      default: // production
        return const ISpectHttpInterceptorSettings(
          enableRedaction: true,
        );
    }
  }
}
```

### Conditional Interceptor Setup

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
    redactor.ignoreValues(['<placeholder-secret>']);
    
    client.interceptors.add(
      ISpectHttpInterceptor(
        logger: iSpectify,
        redactor: redactor,
        settings: HttpConfig.getSettings(),
      ),
    );
  }
}

// Close the underlying client if created outside the app lifecycle to free resources.
```

## Examples

See the [example/](example/) directory for complete integration examples with different HTTP client configurations.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

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