# ISpect

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Logging and inspection tool for Flutter development and testing</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispect">
      <img src="https://img.shields.io/pub/v/ispect.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispect/score">
      <img src="https://img.shields.io/pub/likes/ispect?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect/score">
      <img src="https://img.shields.io/pub/points/ispect?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **ISpect** is a debugging and inspection toolkit designed specifically for Flutter applications. 

<div align="center">

📊 **Real-time Monitoring** • 🐛 **Debugging** • 🔍 **Inspection** • ⚡ **Performance Tracking**

</div>

ISpect empowers Flutter developers with a suite of debugging tools that seamlessly integrate into your development workflow. From monitoring HTTP requests in real-time to tracking performance metrics and managing application state, ISpect provides an intuitive interface that makes debugging efficient and insightful.

### 🎯 Key Capabilities

- 🌐 **Network Monitoring**: Detailed HTTP request/response inspection with error tracking
- 📝 **Comprehensive Logging**: Advanced logging system with categorization and filtering
- ⚡ **Performance Analysis**: Real-time performance metrics and monitoring
- 🔍 **UI Inspector**: Widget hierarchy inspection with color picker and layout analysis  
- 📱 **Device Information**: System and app metadata collection
- 🐛 **Bug Reporting**: Integrated feedback system with screenshot capture
- 🗄️ **Cache Management**: Application cache inspection and management

## 🏗️ Architecture

ISpect is built as a modular system with specialized packages:

| Package | Purpose | Version |
|---------|---------|---------|
| [ispect](packages/ispect) | Core debugging interface and tools | [![pub](https://img.shields.io/pub/v/ispect.svg)](https://pub.dev/packages/ispect) |
| [ispectify](packages/ispectify) | Foundation logging system (based on Talker) | [![pub](https://img.shields.io/pub/v/ispectify.svg)](https://pub.dev/packages/ispectify) |
| [ispectify_dio](packages/ispectify_dio) | Dio HTTP client integration | [![pub](https://img.shields.io/pub/v/ispectify_dio.svg)](https://pub.dev/packages/ispectify_dio) |
| [ispectify_http](packages/ispectify_http) | Standard HTTP client integration | [![pub](https://img.shields.io/pub/v/ispectify_http.svg)](https://pub.dev/packages/ispectify_http) |
| [ispectify_bloc](packages/ispectify_bloc) | BLoC state management integration | [![pub](https://img.shields.io/pub/v/ispectify_bloc.svg)](https://pub.dev/packages/ispectify_bloc) |
| [ispect_jira](packages/ispect_jira) | Jira ticket creation integration | [![pub](https://img.shields.io/pub/v/ispect_jira.svg)](https://pub.dev/packages/ispect_jira) |

## ✨ Features

### 🔍 Network Inspection
- Real-time HTTP request/response monitoring
- Detailed request headers, body, and parameters
- Response data with status codes and timing
- Error logging with stack traces
- Support for both Dio and standard HTTP clients

### 📊 Advanced Logging
- Structured log categorization (info, debug, warning, error)
- Custom log types with color coding
- Real-time log filtering and search
- Export functionality for logs
- BLoC event and state change tracking

### 🎯 UI Development Tools
- Widget inspector with hierarchy visualization
- Color picker for design consistency
- Layout analysis and debugging
- Performance overlay with FPS monitoring
- Screenshot capture with annotation tools

### 📱 Device & Environment Info
- Device specifications and capabilities
- Application metadata and build information
- Cache usage monitoring and management
- System resource utilization

### 🐛 Bug Reporting
- Integrated feedback system
- Screenshot capture with drawing tools
- Automatic device and app context collection
- Jira integration for ticket creation

### 🌐 Internationalization
- Support for 12 languages: English, Russian, Kazakh, Chinese, Spanish, French, German, Portuguese, Arabic, Korean, Japanese, Hindi
- Extensible localization system


## 📱 Interface Preview

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/panel.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/logs.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/detailed_http_request.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/detailed_http_response.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/inspector.png?raw=true" width="160" />
</div>

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/color_picker.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/feedback.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/cache.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/device_info.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/info.png?raw=true" width="160" />
</div>

## 🚀 Quick Start

### 📦 Installation

Add ISpect to your `pubspec.yaml`:

```yaml
dependencies:
  ispect: ^4.1.3

dev_dependencies:
  # For HTTP logging (choose one)
  ispectify_dio: ^4.1.3      # For Dio
  ispectify_http: ^4.1.3     # For standard HTTP
  
  # Optional integrations
  ispectify_bloc: ^4.1.3     # For BLoC logging
  ispect_jira: ^4.1.3        # For Jira integration
```

### ⚙️ Basic Setup

```dart
import 'package:ispect/ispect.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  // Initialize ISpectify for logging
  final ispectify = ISpectify();
  
  // Wrap your app with ISpect
  ISpect.run(
    () => runApp(MyApp()),
    ispectify: ispectify,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ISpectScopeWrapper(
      child: MaterialApp(
        // Add ISpect to your app
        builder: (context, child) => ISpectBuilder(
          child: child ?? const SizedBox.shrink(),
        ),
        
        // Add navigation observer
        navigatorObservers: [
          ISpectNavigatorObserver(),
        ],
        
        // Add localizations
        localizationsDelegates: [
          ...ISpectLocalizations.localizationDelegates([
            // Your existing delegates
          ]),
        ],
        
        home: HomePage(),
      ),
    );
  }
}
```

### 🌐 HTTP Integration

#### 🔧 For Dio:
```dart
import 'package:ispectify_dio/ispectify_dio.dart';

final dio = Dio()
  ..interceptors.add(
    ISpectifyDioInterceptor(ispectify: ISpect.read(context).ispectify),
  );
```

#### 📡 For standard HTTP:
```dart
import 'package:ispectify_http/ispectify_http.dart';

final client = InterceptedClient.build(
  interceptors: [
    ISpectifyHttpLogger(
      ispectify: ISpect.read(context).ispectify,
    ),
  ],
);
```

### 🧊 BLoC Integration

```dart
import 'package:ispectify_bloc/ispectify_bloc.dart';

void main() {
  // Initialize BLoC observer
  Bloc.observer = ISpectifyBlocObserver(
    ispectify: ISpectify(),
  );
  
  ISpect.run(
    () => runApp(MyApp()),
    ispectify: ispectify,
  );
}
```

## ⚙️ Advanced Configuration

### 🎨 Custom Theming

```dart
ISpectScopeWrapper(
  theme: ISpectTheme(
    logColors: {
      'custom-log': Colors.purple,
    },
    logIcons: {
      'http-request': Icons.send,
      'http-response': Icons.receipt,
    },
  ),
  child: MaterialApp(/* ... */),
)
```

### 🎛️ Panel Customization

```dart
ISpectScopeWrapper(
  options: ISpectOptions(
    panelButtons: [
      ('Custom Action', Icons.star, () {
        // Custom action
      }),
    ],
  ),
  child: MaterialApp(/* ... */),
)
```

### 🗺️ Router Integration (GoRouter)

For GoRouter, add a listener to track route changes:

```dart
_router.routerDelegate.addListener(() {
  final location = _router.routerDelegate
    .currentConfiguration.last.matchedLocation;
  ISpect.route(location);
});
``` 

## 📚 Examples

Complete example applications are available in each package's `example/` directory:

- 📖 [Basic Example](packages/ispect/example/) - Core functionality demonstration
- 🎫 [Jira Integration Example](packages/ispect_jira/example/) - Bug reporting workflow
- 🌐 [HTTP Logging Examples](packages/ispectify_http/example/) - Network monitoring setup

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

ISpect builds upon several excellent open-source packages:
- [Talker](https://pub.dev/packages/talker) - Logging foundation
- [Feedback](https://pub.dev/packages/feedback) - User feedback system
- [Inspector](https://pub.dev/packages/inspector) - Widget inspection

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>