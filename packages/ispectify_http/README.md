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
- ⚡ **Performance Metrics**: Request/response timing and size tracking
- 🎛️ **Lightweight**: Minimal overhead using http_interceptor package

## 🔧 Configuration Options

### Basic Setup

```dart
final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

// Initialize in ISpect.run onInit callback
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

### File Upload Example

```dart
// Upload file using MultipartRequest
final List<int> bytes = [1, 2, 3]; // File data
const String filename = 'file.txt';

final http_interceptor.MultipartRequest request =
    http_interceptor.MultipartRequest(
  'POST',
  Uri.parse('https://api.example.com/upload'),
);

request.files.add(http_interceptor.MultipartFile.fromBytes(
  'file', // Field name
  bytes,
  filename: filename,
));

// Send request - will be automatically logged
client.send(request);
```

## 📦 Installation

Add ispectify_http to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_http: ^4.3.0
```

## 🚀 Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

void main() {
  final ISpectify iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
    logger: iSpectify,
    onInit: () {
      // Add ISpectify HTTP interceptor
      client.interceptors.add(
        ISpectHttpInterceptor(iSpectify: iSpectify),
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
                  // All HTTP requests will be automatically logged
                  await client.get(
                    Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
                  );
                },
                child: const Text('Send HTTP Request'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Error requests are also logged
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