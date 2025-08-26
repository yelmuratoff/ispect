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
- 🔒 **Sensitive Data Redaction**: Centralized redaction for headers and bodies (enabled by default, configurable)
- ⚡ **Performance Metrics**: Request/response timing and size tracking
- 🎛️ **Configurable**: Flexible configuration options for different environments

## 🔧 Configuration Options

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
        iSpectify: iSpectify,
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
    iSpectify: iSpectify,
    settings: const ISpectDioInterceptorSettings(enableRedaction: false),
  ),
);

// Provide a custom redactor
final redactor = RedactionService();
redactor.ignoreKeys(['x-debug']);
redactor.ignoreValues(['sample-token']);

dio.interceptors.add(
  ISpectDioInterceptor(
    iSpectify: iSpectify,
    redactor: redactor,
  ),
);
```

### Advanced Configuration with Filters

```dart
dio.interceptors.add(
  ISpectDioInterceptor(
    iSpectify: iSpectify,
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

mainDio.interceptors.add(ISpectDioInterceptor(iSpectify: iSpectify));
uploadDio.interceptors.add(ISpectDioInterceptor(iSpectify: iSpectify));
```

## 📦 Installation

Add ispectify_dio to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_dio: ^4.3.1-dev02
```

## 🚀 Quick Start

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

void main() {
  final ISpectify iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
    logger: iSpectify,
    onInit: () {
      // Add ISpectify Dio interceptor
      dio.interceptors.add(
        ISpectDioInterceptor(
          iSpectify: iSpectify,
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
                  // All Dio requests will be automatically logged
                  dio.get<dynamic>('/posts/1');
                },
                child: const Text('Send GET Request'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Error requests are also logged
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
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>