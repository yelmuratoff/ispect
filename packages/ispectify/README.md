<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Foundation logging system for ISpect toolkit (based on Talker)</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify">
      <img src="https://img.shields.io/pub/v/ispectify.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify/score">
      <img src="https://img.shields.io/pub/likes/ispectify?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify/score">
      <img src="https://img.shields.io/pub/points/ispectify?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## Overview

> **ISpectify** is the foundation logging system that powers the ISpect debugging toolkit.

ISpectify is the logging foundation for the ISpect ecosystem. It builds on the Talker logging library and adds features for debugging and monitoring Flutter applications.

### Key Features

- Structured Logging: Advanced logging with categorization and filtering
- Custom Log Types: Define your own log types with custom colors and icons
- Real-time Filtering: Filter logs by type, level, and custom criteria
- Performance Monitoring: Track application performance metrics
- Export Functionality: Export logs for analysis and debugging
- Easy Integration: Simple setup with minimal configuration

## Configuration

### Settings

```dart
final logger = ISpectify(
    logger: ISpectifyLogger(
        settings: LoggerSettings(
      enableColors: false,
    )),
    options: ISpectifyOptions(
      enabled: true,
      useHistory: true,
      useConsoleLogs: true,
      maxHistoryItems: 10000,
      logTruncateLength: 10000,
      titles: {
        'error': 'Error Logs',
        'info': 'Info Logs',
        'debug': 'Debug Logs',
      },
      colors: {
        'error': AnsiPen()..red(),
        'info': AnsiPen()..blue(),
        'debug': AnsiPen()..white(),
      },
    ),
  );
```

### Custom Log Types

```dart
class CustomLog extends ISpectifyData {
  CustomLog(
    String super.message,
  ) : super(
          key: 'custom_log',
          title: 'Custom Log',
        );
}

logger.logCustom(CustomLog('This is a custom log message'));
```

## Installation

Add ispectify to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify: ^4.3.3
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

// Use dart define to control ISpectify inclusion
const bool kEnableISpectify = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

class CustomLog extends ISpectifyData {
  CustomLog(
    String super.message,
  ) : super(
          key: 'custom_log',
          title: 'Custom Log',
        );
}

void main() {
  ISpectify? logger;
  
  if (kEnableISpectify) {
    // Initialize ISpectify only in development/staging
    logger = ISpectify(
      logger: ISpectifyLogger(
          settings: LoggerSettings(
        enableColors: false,
      )),
      options: ISpectifyOptions(
        enabled: true,
        useHistory: true,
        useConsoleLogs: true,
        maxHistoryItems: 10000,
        logTruncateLength: 10000,
        titles: {
          'error': 'Error Logs',
          'info': 'Info Logs',
          'debug': 'Debug Logs',
        },
        colors: {
          'error': AnsiPen()..red(),
          'info': AnsiPen()..blue(),
          'debug': AnsiPen()..white(),
        },
      ),
    );

    logger.info('ISpectify initialized successfully');

    // Wrap your app with ISpect
    ISpect.run(
      () => runApp(MyApp()),
      logger: logger,
    );
  } else {
    // Production run without ISpectify
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpectify Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (kEnableISpectify) {
                    ISpect.logger.info('Info log message');
                  }
                },
                child: const Text('Log Info'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (kEnableISpectify) {
                    ISpect.logger.logCustom(CustomLog('Custom log message'));
                  }
                },
                child: const Text('Log Custom'),
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

### Production-Safe Logging

```dart
// Create a logger wrapper that respects environment settings
class SafeLogger {
  static const bool _isEnabled = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
  static ISpectify? _instance;
  
  static ISpectify? get instance {
    if (!_isEnabled) return null;
    return _instance ??= _createLogger();
  }
  
  static ISpectify _createLogger() {
    return ISpectify(
      logger: ISpectifyLogger(
        settings: LoggerSettings(
          enableColors: kDebugMode, // Disable colors in headless/CI for cleaner output
        )
      ),
      options: ISpectifyOptions(
        enabled: true,
        useHistory: true,
        useConsoleLogs: kDebugMode,
        maxHistoryItems: 10000,
        logTruncateLength: 10000,
      ),
    );
  }
  
  // Safe logging methods that check environment
  static void info(String message) {
    instance?.info(message);
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    instance?.error(message, error, stackTrace);
  }
  
  static void debug(String message) {
    instance?.debug(message);
  }
}
```

### Custom Configuration

```dart
// Environment-specific logger configuration
ISpectify createLogger() {
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  final bool isProd = environment == 'production';
  return ISpectify(
    logger: ISpectifyLogger(
      settings: LoggerSettings(
        enableColors: !isProd,
        lineLength: environment == 'development' ? 120 : 80,
      )
    ),
    options: ISpectifyOptions(
      enabled: !isProd,
      useHistory: true,
      useConsoleLogs: environment == 'development',
      maxHistoryItems: environment == 'development' ? 10000 : 2000,
      logTruncateLength: environment == 'development' ? 10000 : 2000,
      titles: {
        'error': 'Errors',
        'warning': 'Warnings', 
        'info': 'Information',
        'debug': 'Debug Info',
      },
    ),
  );
}
```

### Memory & History Tuning

Large history buffers increase memory usage. Adjust for CI, tests, or low-end devices:

```dart
ISpectifyOptions(
  maxHistoryItems: 2000, // Lower for constrained environments
  logTruncateLength: 4000, // Shorter entries reduce memory footprint
);
```

### Redaction Guidance

Prefer key-based masking (e.g. 'authorization', 'token', 'apiKey'). Avoid hardcoding actual secret values in ignoreValues; use placeholder markers instead. Disable redaction only with synthetic or non-sensitive data.

## Examples

See the [example/](example/) directory for usage examples and integration patterns.

## 🏗️ Architecture

ISpectify serves as the logging foundation for the ISpect ecosystem:

| Component | Description |
|-----------|-----------|
| **Core Logger** | Based on Talker with enhanced features |
| **Log Filtering** | Advanced filtering and search capabilities |
| **Performance Tracking** | Built-in performance monitoring |
| **Export System** | Log export and analysis tools |
| **Integration Layer** | Seamless integration with ISpect toolkit |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispect](../ispect) - Main debugging interface
- [ispectify_dio](../ispectify_dio) - Dio HTTP client integration
- [ispectify_http](../ispectify_http) - Standard HTTP client integration
- [ispectify_bloc](../ispectify_bloc) - BLoC state management integration

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>