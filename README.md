<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Logging and inspector tool for Flutter development and testing</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispect">
      <img src="https://img.shields.io/pub/v/ispect.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
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

> **ISpect** is the main debugging and inspection toolkit designed specifically for Flutter applications.

<div align="center">

📊 **Real-time Monitoring** • 🐛 **Debugging** • 🔍 **Inspection** • ⚡ **Performance Tracking**

</div>

ISpect empowers Flutter developers with a suite of debugging tools that seamlessly integrate into your development workflow. From monitoring HTTP requests in real-time to tracking performance metrics and managing application state, ISpect provides an intuitive interface that makes debugging efficient and insightful.

### 🎯 Key Features

- 🌐 **Network Monitoring**: Detailed HTTP request/response inspection with error tracking
- 📝 **Logging**: Advanced logging system with categorization and filtering
- ⚡ **Performance Analysis**: Real-time performance metrics and monitoring
- 🔍 **UI Inspector**: Widget hierarchy inspection with color picker and layout analysis
- 📱 **Device Information**: System and app metadata collection
- 🐛 **Bug Reporting**: Integrated feedback system with screenshot capture
- 🗄️ **Cache Management**: Application cache inspection and management

## 🌐 Internationalization
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

## 📦 Installation

Add ispect to your `pubspec.yaml`:

```yaml
dependencies:
  ispect: ^4.3.2
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
  Widget app = MaterialApp(/* your app */);
  
  // Wrap with ISpect only when enabled
  if (kEnableISpect) {
    app = ISpectBuilder(child: app);
  }
  
  return app;
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
  // Initialize ISpectify for logging
  final ISpectify logger = ISpectifyFlutter.init();

  // Wrap your app with ISpect
  ISpect.run(
    () => runApp(MyApp()),
    logger: logger,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      localizationsDelegates: kEnableISpect
          ? ISpectLocalizations.localizationDelegates([
              // Add your localization delegates here
            ])
          : [
              // Your regular localization delegates
            ],
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpect Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              if (kEnableISpect) {
                ISpect.logger.info('Button pressed!');
              }
            },
            child: const Text('Press me'),
          ),
        ),
      ),
    );

    // Wrap with ISpect only when enabled
    if (kEnableISpect) {
      app = ISpectBuilder(child: app);
    }

    return app;
  }
}
```

## ⚙️ Advanced Configuration

### 🛡️ Environment-Based Setup

```dart
// Create a dedicated ISpect configuration file
// lib/config/ispect_config.dart

import 'package:flutter/foundation.dart';

class ISpectConfig {
  static const bool isEnabled = bool.fromEnvironment(
    'ENABLE_ISPECT',
    defaultValue: kDebugMode, // Only enable in debug by default
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  // Only enable in development and staging
  static bool get shouldInitialize => 
    isEnabled && (environment != 'production');
}
```

### 🎨 Custom Theming (Development Only)

```dart
// Wrap theming configuration in conditional check
Widget _buildApp() {
  Widget app = MaterialApp(/* your app */);
  
  if (ISpectConfig.shouldInitialize) {
    app = ISpectBuilder(
      theme: ISpectTheme(
        pageTitle: 'Debug Panel',
        lightBackgroundColor: Colors.white,
        darkBackgroundColor: Colors.black,
        lightDividerColor: Colors.grey.shade300,
        darkDividerColor: Colors.grey.shade800,
        logColors: {
          'error': Colors.red,
          'info': Colors.blue,
        },
        logIcons: {
          'error': Icons.error,
          'info': Icons.info,
        },
        logDescriptions: [
          LogDescription(
            key: 'riverpod-add',
            isDisabled: true,
          ),
          LogDescription(
            key: 'riverpod-update',
            isDisabled: true,
          ),
          LogDescription(
            key: 'riverpod-dispose',
            isDisabled: true,
          ),
          LogDescription(
            key: 'riverpod-fail',
            isDisabled: true,
          ),
        ],
      ),
      child: app,
    );
  }
  
  return app;
}
```

### 🎛️ Panel Customization (Development Only)

```dart
Widget _buildAppWithISpect(Widget child) {
  if (!ISpectConfig.shouldInitialize) {
    return child; // Return app without ISpect in production
  }
  
  return ISpectBuilder(
    options: ISpectOptions(
      locale: const Locale('en'),
      isFeedbackEnabled: true,
      actionItems: [
        ISpectActionItem(
            onTap: (BuildContext context) {
              // Development-only actions
            },
            title: 'Dev Action',
            icon: Icons.build),
      ],
      panelItems: [
        ISpectPanelItem(
          enableBadge: false,
          icon: Icons.settings,
          onTap: (context) {
            // Handle settings tap
          },
        ),
      ],
      panelButtons: [
        ISpectPanelButtonItem(
            icon: Icons.info,
            label: 'Debug Info',
            onTap: (context) {
              // Handle debug info tap
            }),
      ],
    ),
    child: child,
  );
}
```

### 📱 Build Configuration Examples

```bash
# Development with ISpect
flutter run --dart-define=ENABLE_ISPECT=true --dart-define=ENVIRONMENT=development

# Staging with ISpect
flutter build apk --dart-define=ENABLE_ISPECT=true --dart-define=ENVIRONMENT=staging

# Production without ISpect (recommended)
flutter build apk --dart-define=ENABLE_ISPECT=false --dart-define=ENVIRONMENT=production

# Or use flavor-specific configurations
flutter build apk --flavor production # ISpect automatically disabled
```

## 📚 Examples

Complete example applications are available in the [example/](example/) directory demonstrating core functionality.

## 🏗️ Architecture

ISpect is built as a modular system with specialized packages:

| Package | Purpose | Version |
|---------|---------|---------|
| [ispect](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect) | Core debugging interface and tools | [![pub](https://img.shields.io/pub/v/ispect.svg)](https://pub.dev/packages/ispect) |
| [ispectify](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify) | Foundation logging system (based on Talker) | [![pub](https://img.shields.io/pub/v/ispectify.svg)](https://pub.dev/packages/ispectify) |
| [ispectify_dio](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_dio) | Dio HTTP client integration | [![pub](https://img.shields.io/pub/v/ispectify_dio.svg)](https://pub.dev/packages/ispectify_dio) |
| [ispectify_http](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_http) | Standard HTTP client integration | [![pub](https://img.shields.io/pub/v/ispectify_http.svg)](https://pub.dev/packages/ispectify_http) |
| [ispectify_ws](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_ws) | WebSocket connection monitoring | [![pub](https://img.shields.io/pub/v/ispectify_ws.svg)](https://pub.dev/packages/ispectify_ws) |
| [ispectify_bloc](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_bloc) | BLoC state management integration | [![pub](https://img.shields.io/pub/v/ispectify_bloc.svg)](https://pub.dev/packages/ispectify_bloc) |
| [ispect_jira](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect_jira) | Jira ticket creation integration | [![pub](https://img.shields.io/pub/v/ispect_jira.svg)](https://pub.dev/packages/ispect_jira) |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [ispectify](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify) - Foundation logging system
- [ispectify_dio](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_dio) - Dio HTTP client integration
- [ispectify_http](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_http) - Standard HTTP client integration
- [ispectify_ws](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_ws) - WebSocket connection monitoring
- [ispectify_bloc](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_bloc) - BLoC state management integration
- [ispect_jira](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect_jira) - Jira ticket creation integration

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>