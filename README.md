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

## TL;DR

Drop-in Flutter debug panel: network + database + logs + performance + UI inspector. Add flag, wrap app, ship safer builds.

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

## 🏗️ Architecture

Modular packages. Include only what you use:

| Package | Role | Version |
|---------|------|---------|
| [ispect](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect) | Core panel + inspectors | [![pub](https://img.shields.io/pub/v/ispect.svg)](https://pub.dev/packages/ispect) |
| [ispectify](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify) | Logging backbone | [![pub](https://img.shields.io/pub/v/ispectify.svg)](https://pub.dev/packages/ispectify) |
| [ispectify_dio](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_dio) | Dio HTTP capture | [![pub](https://img.shields.io/pub/v/ispectify_dio.svg)](https://pub.dev/packages/ispectify_dio) |
| [ispectify_http](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_http) | http package capture | [![pub](https://img.shields.io/pub/v/ispectify_http.svg)](https://pub.dev/packages/ispectify_http) |
| [ispectify_ws](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_ws) | WebSocket traffic | [![pub](https://img.shields.io/pub/v/ispectify_ws.svg)](https://pub.dev/packages/ispectify_ws) |
| [ispectify_db](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_db) | Database operations | [![pub](https://img.shields.io/pub/v/ispectify_db.svg)](https://pub.dev/packages/ispectify_db) |
| [ispectify_bloc](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_bloc) | BLoC events/states | [![pub](https://img.shields.io/pub/v/ispectify_bloc.svg)](https://pub.dev/packages/ispectify_bloc) |
| [ispect_jira](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect_jira) | Jira issue export | [![pub](https://img.shields.io/pub/v/ispect_jira.svg)](https://pub.dev/packages/ispect_jira) |

## Overview

> **ISpect** is the main debugging and inspection toolkit designed specifically for Flutter applications. Includes network, database, performance, UI, and device tools.

Provides network, database, performance, widget tree, logging and device insight tooling via a lightweight in‑app panel.

### Key Features

- Network Monitoring: Detailed HTTP request/response inspection with error tracking
- Database Logging: Passive DB operation tracing with duration, errors, redaction
- Logging: Advanced logging system with categorization and filtering
- Performance Analysis: Real-time performance metrics and monitoring
- UI Inspector: Widget hierarchy inspection with color picker and layout analysis
- Device Information: System and app metadata collection
- Bug Reporting: Integrated feedback system with screenshot capture
- Cache Management: Application cache inspection and management

## Logging Configuration
Core logging powered by ISpectify. Configure via `ISpectifyOptions` passed to the logger you supply into `ISpect.run`.

### Typical Setup
```dart
final logger = ISpectify(
  options: ISpectifyOptions(
    enabled: true,
    useHistory: true,
    useConsoleLogs: kDebugMode,
    maxHistoryItems: 5000,
    logTruncateLength: 4000,
  ),
);
ISpect.run(() => runApp(App()), logger: logger);
```

### Disable Console Noise
```dart
logger.configure(options: logger.options.copyWith(useConsoleLogs: false));
```

### Stateless (No History)
```dart
logger.configure(options: logger.options.copyWith(useHistory: false));
```
Stream subscribers still receive real-time events.

### Filter Example
```dart
class WarningsAndAbove implements ISpectifyFilter {
  @override
  bool apply(ISpectifyData d) => (d.logLevel?.priority ?? 0) >= LogLevel.warning.priority;
}
final logger = ISpectify(filter: WarningsAndAbove());
```

For advanced knobs (redaction, dynamic reconfigure, zero-allocation tips) see the ISpectify README.

## Internationalization
- Bundled locales: en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi
- Extend via ISpectLocalizations delegate override

## Installation

Add ispect to your `pubspec.yaml`:

```yaml
dependencies:
  ispect: ^4.4.0-dev09
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

Enable with a --dart-define flag. In release without the flag, code is tree‑shaken (no size / perf impact). Wrap all init behind the boolean and avoid committing builds with it enabled.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

### Recommended Setup with Dart Define Constants

**1. Flag-driven initialization**
```dart
const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);
void main() {
  if (kEnableISpect) {
    _bootstrapDebug();
  } else {
    runApp(const MyApp());
  }
}
void _bootstrapDebug() {
  final logger = ISpectifyFlutter.init();
  ISpect.run(() => runApp(const MyApp()), logger: logger);
}
```
**2. Build commands**
```bash
# Dev / QA
flutter run --dart-define=ENABLE_ISPECT=true
# Release (default false)
flutter build apk
```
**3. Verify exclusion**
Compare sizes: build once with flag true and another without; the delta should reflect removed debug assets.

**Benefits**
- Zero production footprint (tree-shaken)
- Prevents accidental data exposure
- Faster startup & lower memory in release
- Clear audit trail via explicit flag

</details>

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

### Minimal Setup

```dart
// main.dart (minimal enable)
const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT');
void main() {
  if (!kEnableISpect) return runApp(const MyApp());
  final logger = ISpectifyFlutter.init();
  ISpect.run(() => runApp(const MyApp()), logger: logger);
}

// Run with: flutter run --dart-define=ENABLE_ISPECT=true
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

ISpect integrates with various Flutter packages through companion packages. Below are guides for integrating ISpect with HTTP clients, database operations, state management, WebSocket connections, and navigation.

### Required Dependencies

Add the following packages to your `pubspec.yaml` based on your needs:

```yaml
dependencies:
  # Core ISpect
  ispect: ^4.4.0-dev09
  
  # HTTP integrations (choose one or both)
  ispectify_dio: ^4.4.0-dev09      # For Dio HTTP client
  ispectify_http: ^4.4.0-dev09     # For standard HTTP package
  
  # Database integration
  ispectify_db: ^4.4.0-dev09       # For database operation logging
  
  # WebSocket integration
  ispectify_ws: ^4.4.0-dev09       # For WebSocket monitoring
  
  # State management integration
  ispectify_bloc: ^4.4.0-dev09     # For BLoC state management
  
  # Optional: Jira integration
  ispect_jira: ^4.4.0-dev09        # For automated bug reporting
```

### HTTP Integration

#### Dio HTTP Client

For Dio integration, use the `ispectify_dio` package:

```yaml
dependencies:
  ispectify_dio: ^4.4.0-dev09
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
  ispectify_http: ^4.4.0-dev09
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

### Database Integration

For database operation logging, use the `ispectify_db` package:

```yaml
dependencies:
  ispectify_db: ^4.4.0-dev09
```

```dart
import 'package:sqflite/sqflite.dart';
import 'package:ispectify_db/ispectify_db.dart';

// Configure database logging
ISpectDbCore.config = const ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  attachStackOnError: true,
  enableTransactionMarkers: false,
  slowQueryThreshold: Duration(milliseconds: 400),
);

// Log database operations
final rows = await ISpect.logger.dbTrace<List<Map<String, Object?>>>(
  source: 'sqflite',
  operation: 'query',
  statement: 'SELECT * FROM users WHERE id = ?',
  args: [userId],
  table: 'users',
  run: () => db.rawQuery('SELECT * FROM users WHERE id = ?', [userId]),
  projectResult: (rows) => {'rows': rows.length},
);
```

### WebSocket Integration

For WebSocket monitoring, use the `ispectify_ws` package:

```yaml
dependencies:
  ispectify_ws: ^4.4.0-dev09
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
  ispectify_bloc: ^4.4.0-dev09
```

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    Bloc.observer = ISpectBlocObserver(
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

#### Database Example

```dart
// Database redaction is configured globally
ISpectDbCore.config = const ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
);
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
      LogDescription(key: 'db-query', isDisabled: false),
      LogDescription(key: 'db-result', isDisabled: false),
      LogDescription(key: 'db-error', isDisabled: false),
      LogDescription(key: 'route', isDisabled: false),
      LogDescription(key: 'print', isDisabled: true),
      LogDescription(key: 'analytics', isDisabled: true),
    ],
  ),
  child: child,
)
```

Available log keys: `bloc-*`, `http-*`, `db-*`, `route`, `print`, `analytics`, `error`, `debug`, `info`

## Examples

Complete example applications are available in the [example/](example/) directory demonstrating core functionality.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispectify](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify) - Foundation logging system
- [ispectify_dio](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_dio) - Dio HTTP client integration
- [ispectify_http](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_http) - Standard HTTP client integration
- [ispectify_ws](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_ws) - WebSocket connection monitoring
- [ispectify_db](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_db) - Database operation logging
- [ispectify_bloc](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_bloc) - BLoC state management integration
- [ispect_jira](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect_jira) - Jira ticket creation integration

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>