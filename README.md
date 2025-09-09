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

## Overview

> **ISpect** is the main debugging and inspection toolkit designed specifically for Flutter applications.

ISpect provides comprehensive debugging capabilities for Flutter applications, including network monitoring, performance tracking, and UI inspection tools.

### Key Features

- Network Monitoring: Detailed HTTP request/response inspection with error tracking
- Logging: Advanced logging system with categorization and filtering
- Performance Analysis: Real-time performance metrics and monitoring
- UI Inspector: Widget hierarchy inspection with color picker and layout analysis
- Device Information: System and app metadata collection
- Bug Reporting: Integrated feedback system with screenshot capture
- Cache Management: Application cache inspection and management

## Internationalization
- Support for 12 languages: English, Russian, Kazakh, Chinese, Spanish, French, German, Portuguese, Arabic, Korean, Japanese, Hindi
- Extensible localization system

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
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/feedback.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/cache.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/device_info.png?raw=true" width="160" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/info.png?raw=true" width="160" />
</div>

## Installation

Add ispect to your `pubspec.yaml`:

```yaml
dependencies:
  ispect: ^4.3.4
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
    return MaterialApp(
      localizationsDelegates: kEnableISpect
          ? ISpectLocalizations.localizationDelegates([
              // Add your localization delegates here
            ])
          : [
              // Your regular localization delegates
            ],
      // Conditionally add ISpectBuilder in MaterialApp builder
      builder: (context, child) {
        if (kEnableISpect) {
          return ISpectBuilder(child: child ?? const SizedBox.shrink());
        }
        return child ?? const SizedBox.shrink();
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpect Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
                ISpect.logger.info('Button pressed!');
            },
            child: const Text('Press me'),
          ),
        ),
      ),
    );
  }
}
```

## Advanced Configuration

### Environment-Based Setup

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

### Custom Theming (Development Only)

```dart
// Wrap theming configuration in conditional check
Widget build(BuildContext context) {
  return MaterialApp(
    builder: (context, child) {
      if (ISpectConfig.shouldInitialize) {
        return ISpectBuilder(
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
          child: child ?? const SizedBox.shrink(),
        );
      }
      return child ?? const SizedBox.shrink();
    },
    home: Scaffold(/* your app content */),
  );
}
```

### Panel Customization (Development Only)

```dart
Widget build(BuildContext context) {
  return MaterialApp(
    builder: (context, child) {
      if (!ISpectConfig.shouldInitialize) {
        return child ?? const SizedBox.shrink(); // Return app without ISpect in production
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
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(/* your app content */),
  );
}
```

### Build Configuration Examples

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

## Integration Guides

ISpect integrates with various Flutter packages through companion packages. Below are guides for integrating ISpect with HTTP clients, state management, WebSocket connections, and navigation.

### Required Dependencies

Add the following packages to your `pubspec.yaml` based on your needs:

```yaml
dependencies:
  # Core ISpect
  ispect: ^4.3.4
  
  # HTTP integrations (choose one or both)
  ispectify_dio: ^4.3.4      # For Dio HTTP client
  ispectify_http: ^4.3.4     # For standard HTTP package
  
  # WebSocket integration
  ispectify_ws: ^4.3.4       # For WebSocket monitoring
  
  # State management integration
  ispectify_bloc: ^4.3.4     # For BLoC state management
  
  # Optional: Jira integration
  ispect_jira: ^4.3.4        # For automated bug reporting
```

### HTTP Integration

#### Dio HTTP Client

For Dio integration, use the `ispectify_dio` package:

```yaml
dependencies:
  ispectify_dio: ^4.3.4
```

```dart
import 'package:dio/dio.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
  ),
);

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    dio.interceptors.add(
      ISpectDioInterceptor(
        logger: iSpectify,
        settings: const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestData: true,
          printResponseData: true,
        ),
      ),
    );
    // Avoid also adding Dio's LogInterceptor unless deliberately comparing outputs.
  },
);
```

#### Standard HTTP Client

For standard HTTP package integration, use the `ispectify_http` package:

```yaml
dependencies:
  ispectify_http: ^4.3.4
```

```dart
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    client.interceptors.add(
      ISpectHttpInterceptor(
        logger: iSpectify,
        settings: const ISpectHttpInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
        ),
      ),
    );
  },
);
```

#### Multiple HTTP Clients

You can monitor multiple Dio or HTTP clients simultaneously. Placing interceptor setup inside `onInit` ensures all code is removed from production when the flag is false:

```dart
final Dio mainDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
final Dio uploadDio = Dio(BaseOptions(baseUrl: 'https://upload.example.com'));

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    mainDio.interceptors.add(ISpectDioInterceptor(logger: iSpectify));
    uploadDio.interceptors.add(ISpectDioInterceptor(logger: iSpectify));
  },
);
```

### WebSocket Integration

For WebSocket monitoring, use the `ispectify_ws` package:

```yaml
dependencies:
  ispectify_ws: ^4.3.4
```

```dart
import 'package:ws/ws.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

final interceptor = ISpectWSInterceptor(
  logger: iSpectify,
  settings: const ISpectWSInterceptorSettings(
    enabled: true,
    printSentData: true,
    printReceivedData: true,
    printReceivedMessage: true,
    printErrorData: true,
    printErrorMessage: true,
  ),
);

final client = WebSocketClient(
  WebSocketOptions.common(
    interceptors: [interceptor],
  ),
);

interceptor.setClient(client);
```

### BLoC State Management Integration

For BLoC integration, use the `ispectify_bloc` package:

```yaml
dependencies:
  ispectify_bloc: ^4.3.4
```

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    Bloc.observer = ISpecBlocObserver(
      logger: iSpectify,
    );
  },
);
```

You can also filter specific BLoC logs in the ISpect theme:

```dart
ISpectBuilder(
  theme: const ISpectTheme(
    logDescriptions: [
      LogDescription(
        key: 'bloc-event',
        isDisabled: true,
      ),
      LogDescription(
        key: 'bloc-transition',
        isDisabled: true,
      ),
      LogDescription(
        key: 'bloc-state',
        isDisabled: true,
      ),
    ],
  ),
  child: child,
)
```

### Navigation Integration

To track screen navigation, use `ISpectNavigatorObserver`:

```dart
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _observer = ISpectNavigatorObserver(
    isLogModals: true,
    isLogPages: true,
    isLogGestures: false,
    isLogOtherTypes: true,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [_observer],
      builder: (context, child) {
        return ISpectBuilder(
          observer: _observer,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
```

Navigation events will be logged with the key `route`.

### Sensitive Data Redaction

All integration packages support redaction. Prefer disabling only with synthetic data. Use placeholder values when demonstrating secrets.

#### Dio Example

```dart
final interceptor = ISpectDioInterceptor(
  logger: iSpectify,
  settings: const ISpectDioInterceptorSettings(
    enableRedaction: false, // Only if data is guaranteed non-sensitive
  ),
);
```

#### HTTP Example

```dart
final redactor = RedactionService();
redactor.ignoreKeys(['authorization', 'x-api-key']);
redactor.ignoreValues(['<placeholder-secret>']);
client.interceptors.add(ISpectHttpInterceptor(logger: iSpectify, redactor: redactor));
```

#### WebSocket Example

```dart
final redactor = RedactionService();
redactor.ignoreKeys(['auth_token']);
redactor.ignoreValues(['<placeholder>']);
final interceptor = ISpectWSInterceptor(logger: iSpectify, redactor: redactor);
```

Redaction masks data in headers, bodies, WS messages, and query parameters. Avoid embedding real secrets in code.

### Log Filtering and Customization

```dart
ISpectBuilder(
  theme: const ISpectTheme(
    logDescriptions: [
      LogDescription(key: 'bloc-event', isDisabled: true),
      LogDescription(key: 'bloc-transition', isDisabled: true),
      LogDescription(key: 'bloc-state', isDisabled: true),
      LogDescription(key: 'bloc-create', isDisabled: false),
      LogDescription(key: 'bloc-close', isDisabled: false),
      LogDescription(key: 'http-request', isDisabled: false),
      LogDescription(key: 'http-response', isDisabled: false),
      LogDescription(key: 'http-error', isDisabled: false),
      LogDescription(key: 'route', isDisabled: false),
      LogDescription(key: 'print', isDisabled: true),
      LogDescription(key: 'analytics', isDisabled: true),
    ],
  ),
  child: child,
)
```

Available log keys: `bloc-*`, `http-*`, `route`, `print`, `analytics`, `error`, `debug`, `info`

## Examples

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

## Related Packages

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