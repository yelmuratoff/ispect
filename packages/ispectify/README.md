<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p><strong>In-app debugging toolkit for Flutter</strong></p>

  <p>
    <a href="https://pub.dev/packages/ispect">
      <img src="https://img.shields.io/pub/v/ispect?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&labelColor=0360a9&color=2ab7f6" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=for-the-badge&logo=github&labelColor=0360a9&color=2ab7f6" alt="GitHub stars">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispect/score">
      <img src="https://img.shields.io/pub/likes/ispect?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect/score">
      <img src="https://img.shields.io/pub/points/ispect?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispect/downloads">
      <img src="https://img.shields.io/pub/dm/ispect?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>

## What is ISpect?

In-app debugging tool for Flutter. Inspect network requests, logs, and UI during development and testing.

**Features:**
- Network monitoring (Dio, http)
- Structured logging with filtering
- UI inspector
- Observer pattern for external integrations
- Removed from production builds via tree-shaking

## Table of Contents

- [Interface Preview](#interface-preview)
- [Architecture](#architecture)
- [Features](#features)
- [Getting Started](#getting-started)
- [Logger Configuration](#logger-configuration)
- [Internationalization](#internationalization)
- [Production Safety](#production-safety)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)

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
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/cache.png?raw=true" width="160" />
</div>

## Web Demo

**Live Web Demo:** [https://yelmuratoff.github.io/ispect/](https://yelmuratoff.github.io/ispect/)

Drag and drop exported log files to explore them in the browser.

## Architecture

Modular design—add only what you need:

| Package | Role | Version |
|---------|------|---------|
| [ispect](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispect) | Core panel + inspectors | [![pub](https://img.shields.io/pub/v/ispect.svg)](https://pub.dev/packages/ispect) |
| [ispectify](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify) | Logging backbone | [![pub](https://img.shields.io/pub/v/ispectify.svg)](https://pub.dev/packages/ispectify) |
| [ispectify_dio](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_dio) | Dio HTTP capture | [![pub](https://img.shields.io/pub/v/ispectify_dio.svg)](https://pub.dev/packages/ispectify_dio) |
| [ispectify_http](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_http) | http package capture | [![pub](https://img.shields.io/pub/v/ispectify_http.svg)](https://pub.dev/packages/ispectify_http) |
| [ispectify_ws](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_ws) | WebSocket traffic | [![pub](https://img.shields.io/pub/v/ispectify_ws.svg)](https://pub.dev/packages/ispectify_ws) |
| [ispectify_db](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_db) | Database operations | [![pub](https://img.shields.io/pub/v/ispectify_db.svg)](https://pub.dev/packages/ispectify_db) |
| [ispectify_bloc](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_bloc) | BLoC events/states | [![pub](https://img.shields.io/pub/v/ispectify_bloc.svg)](https://pub.dev/packages/ispectify_bloc) |

## Features

### Network Monitoring
Inspect HTTP requests and responses with headers, bodies, timing, and errors.

### Database Operations
Track queries with execution time, result counts, and errors.

### Logging System
- Log levels (info, warning, error, debug)
- Category-based filtering
- Configurable history retention
- Export and sharing
- Observer pattern for third-party integrations

### UI Inspector
Widget tree inspection, layout measurements, color picker.

### Performance Tracking
Frame rates, memory usage, performance metrics.

### Device Information
Device details, app version, platform info.

### Feedback Collection
In-app feedback with screenshot capture and log attachment.

### Observer Pattern

Observers receive log events in real-time for integration with error tracking services.

```dart
import 'dart:developer';
import 'package:ispect/ispect.dart';

// Observer that sends errors to Sentry
class SentryISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) {
    // Send to Sentry
    log('SentryISpectObserver - onError: ${err.message}');
    // Sentry.captureException(err.exception, stackTrace: err.stackTrace);
  }

  @override
  void onException(ISpectLogData err) {
    log('SentryISpectObserver - onException: ${err.message}');
    // Sentry.captureException(err.exception, stackTrace: err.stackTrace);
  }

  @override
  void onLog(ISpectLogData data) {
    // Optionally send high-priority logs to Sentry as breadcrumbs
    log('SentryISpectObserver - onLog: ${data.message}');
  }
}

// Observer that sends data to your backend
class BackendISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) {
    log('BackendISpectObserver - onError: ${err.message}');
    // Send error to your analytics/logging backend
  }

  @override
  void onException(ISpectLogData err) {
    log('BackendISpectObserver - onException: ${err.message}');
  }

  @override
  void onLog(ISpectLogData data) {
    log('BackendISpectObserver - onLog: ${data.message}');
  }
}

void main() {
  final logger = ISpectFlutter.init();

  // Add multiple observers
  logger.addObserver(SentryISpectObserver());
  logger.addObserver(BackendISpectObserver());

  ISpect.run(logger: logger, () => runApp(const MyApp()));
}
```

Observers receive all logs, errors, and exceptions. Use them to forward events to Sentry, Crashlytics, or custom analytics endpoints.

## Getting Started

### Installation

```yaml
dependencies:
  ispect: ^4.7.4
```

### Quick Start

ISpect uses automatic tree-shaking via `kISpectEnabled`. By default, ISpect is **disabled** and completely removed from production builds.

```dart
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

final observer = ISpectNavigatorObserver();

void main() {
  ISpect.run(() => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers: [observer],
      builder: (context, child) => ISpectBuilder(
        options: ISpectOptions(observer: observer),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}
```

**Build Commands:**

```bash
# Development (ISpect enabled)
flutter run --dart-define=ISPECT_ENABLED=true

# Production (ISpect automatically removed via tree-shaking)
flutter build apk
```

> **Note:** When `ISPECT_ENABLED` is not set (default), `ISpect.run()`, `ISpectBuilder`, and `ISpectLocalizations.delegates()` automatically become no-ops, allowing Dart's tree-shaking to remove all ISpect code from your production build.

## Logger Configuration

### Default Setup

```dart
void main() {
  ISpect.run(() => runApp(const MyApp()));
}
```

### Custom Logger Options

Configure the logger during initialization:

```dart
void main() {
  final logger = ISpectFlutter.init(
    options: ISpectLoggerOptions(
      enabled: true,
      useHistory: true,              // Store logs in memory
      useConsoleLogs: kDebugMode,    // Print to console in debug mode
      maxHistoryItems: 5000,         // Keep last 5000 log entries
      logTruncateLength: 4000,       // Truncate long messages
    ),
  );

  ISpect.run(logger: logger, () => runApp(const MyApp()));
}
```

### Quiet Mode (Disable Console Output)

If console logs are too noisy, disable them:

```dart
final logger = ISpectFlutter.init(
  options: const ISpectLoggerOptions(useConsoleLogs: false),
);
ISpect.run(logger: logger, () => runApp(const MyApp()));
```

You can also change this at runtime:

```dart
ISpect.logger.configure(
  options: ISpect.logger.options.copyWith(useConsoleLogs: false),
);
```

### Stateless Mode (No History)

If you don't need log history (e.g., for real-time streaming only):

```dart
final logger = ISpectFlutter.init(
  options: const ISpectLoggerOptions(useHistory: false),
);
ISpect.run(logger: logger, () => runApp(const MyApp()));
```

Logs will still be sent to observers and console, but won't be stored in memory.

### Filtering

Filter logs by priority or custom criteria:

```dart
// Only capture warnings and errors
class WarningsAndAbove implements ISpectFilter {
  @override
  bool apply(ISpectLogData data) {
    return (data.logLevel?.priority ?? 0) >= LogLevel.warning.priority;
  }
}

void main() {
  final logger = ISpectFlutter.init(filter: WarningsAndAbove());
  ISpect.run(logger: logger, () => runApp(const MyApp()));
}
```

For advanced configuration options (redaction, dynamic reconfiguration, performance tuning), see the [ISpectLogger documentation](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify).

## Internationalization

**Supported languages:** en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi

```dart
MaterialApp(
  localizationsDelegates: ISpectLocalizations.delegates(
    delegates: [
      // Add your own localization delegates here
    ],
  ),
  // ...
)
```

You can extend or override translations using the `ISpectLocalizations` delegate.

## Production Safety

> **Security Best Practice:** Debug and logging tools should not be included in production builds. They can expose sensitive data (API keys, tokens, user data, network traffic) and increase app size.

ISpect uses `kISpectEnabled` compile-time constant for automatic tree-shaking. When disabled (default), all ISpect code is removed from production builds.

### Zero-Conditional API

ISpect provides factory methods that handle the `kISpectEnabled` check internally, eliminating conditional logic in your code:

```dart
void main() {
  ISpect.run(() => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers: ISpectNavigatorObserver.observers(),
      builder: (_, child) => ISpectBuilder.wrap(child: child!),
      home: const MyHomePage(),
    );
  }
}
```

**Build Commands:**

```bash
# Development (ISpect enabled)
flutter run --dart-define=ISPECT_ENABLED=true

# Production (ISpect removed via tree-shaking)
flutter build apk
```

### Security recommendations

#### 1. Maximum Security Build

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=debug-info/
```

This enables:
- **Tree-shaking:** Removes unused code (including disabled ISpect)
- **Obfuscation:** Mangles class/method names
- **Debug symbol stripping:** Removes debug information

#### 2. Verified Tree-Shaking Results

| Build | APK Size | libapp.so | "ispect" strings |
|-------|----------|-----------|------------------|
| **Obfuscated Production** | 42.4 MB | - | **6** |
| Non-obfuscated Production | 44.5 MB | 3.8 MB | 34 |
| Development | 51.0 MB | 5.8 MB | 276 |

**Benefits:**

- No data exposure in production
- Zero runtime overhead
- Smaller production builds
- Easier security audits

### Environment-Based Configuration

For more complex setups (dev/staging/prod environments), you can create a configuration file:

```dart
// lib/config/ispect_config.dart
import 'package:flutter/foundation.dart';

class ISpectConfig {
  static const bool isEnabled = bool.fromEnvironment(
    'ISPECT_ENABLED',
    defaultValue: kDebugMode, // Enable in debug mode by default
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Only enable in non-production environments
  static bool get shouldInitialize => isEnabled && environment != 'production';
}
```

Then use it in your `main.dart`:

```dart
void main() {
  if (ISpectConfig.shouldInitialize) {
    ISpect.run(() => runApp(const MyApp()));
  } else {
    runApp(const MyApp());
  }
}
```

Build with environment flags:

```bash
flutter build apk \
  --dart-define=ISPECT_ENABLED=true \
  --dart-define=ENVIRONMENT=staging
```

## Customization

### Theming

```dart
final observer = ISpectNavigatorObserver();

ISpectBuilder(
  options: ISpectOptions(observer: observer),
  theme: ISpectTheme(
    pageTitle: 'Debug Panel',

    // Unified color theming with ISpectDynamicColor
    background: ISpectDynamicColor(
      light: Colors.white,
      dark: Colors.black,
    ),
    divider: ISpectDynamicColor(
      light: Colors.grey.shade300,
      dark: Colors.grey.shade800,
    ),

    // Custom colors for log types
    logColors: {
      'error': Colors.red,
      'warning': Colors.orange,
      'info': Colors.blue,
      'debug': Colors.grey,
    },

    // Custom icons for log types
    logIcons: {
      'error': Icons.error,
      'warning': Icons.warning,
      'info': Icons.info,
      'debug': Icons.bug_report,
    },

    // Custom descriptions for log types
    logDescriptions: {
      'error': 'Critical application errors',
      'info': 'Informational messages',
    },

    // Disable specific log categories
    disabledLogTypes: {
      'riverpod-add',
      'riverpod-update',
      'riverpod-dispose',
      'riverpod-fail',
    },
  ),
  child: child ?? const SizedBox.shrink(),
)
```

### Panel Actions

```dart
final observer = ISpectNavigatorObserver();

ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    locale: const Locale('en'),

    // Custom action items in the menu
    actionItems: [
      ISpectActionItem(
        onTap: (context) {
          // Clear cache, reset state, etc.
        },
        title: 'Clear All Data',
        icon: Icons.delete_sweep,
      ),
      ISpectActionItem(
        onTap: (context) {
          // Switch to a test environment
        },
        title: 'Switch Environment',
        icon: Icons.swap_horiz,
      ),
    ],

    // Custom panel items (icons)
    panelItems: [
      DraggablePanelItem(
        enableBadge: false,
        icon: Icons.settings,
        onTap: (context) {
          // Open settings
        },
      ),
    ],

    // Custom panel buttons (labeled)
    panelButtons: [
      DraggablePanelButtonItem(
        icon: Icons.info,
        label: 'App Info',
        onTap: (context) {
          // Show app version, build number, etc.
        },
      ),
    ],
  ),
  child: child ?? const SizedBox.shrink(),
)
```

### Settings Persistence

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final observer = ISpectNavigatorObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted settings
  final prefs = await SharedPreferences.getInstance();
  final settingsJson = prefs.getString('ispect_settings');
  final initialSettings = settingsJson != null
      ? ISpectSettingsState.fromJson(jsonDecode(settingsJson))
      : null;

  final logger = ISpectFlutter.init();
  ISpect.run(logger: logger, () => runApp(MyApp(initialSettings: initialSettings)));
}

class MyApp extends StatelessWidget {
  final ISpectSettingsState? initialSettings;

  const MyApp({super.key, this.initialSettings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [observer],
      builder: (context, child) => ISpectBuilder(
        options: ISpectOptions(
          observer: observer,
          initialSettings: initialSettings ?? const ISpectSettingsState(
            disabledLogTypes: {'warning'},
            enabled: true,
            useConsoleLogs: true,
            useHistory: true,
          ),
          onSettingsChanged: (settings) async {
            // Save settings when they change
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ispect_settings', jsonEncode(settings.toJson()));
          },
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const MyHomePage(),
    );
  }
}
```

### Custom Callbacks

```dart
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

final observer = ISpectNavigatorObserver();

ISpectBuilder(
  options: ISpectOptions(
    observer: observer,

    // Load log content from external source
    onLoadLogContent: (context) async {
      // Use file_picker to let users select a log file
      // final result = await FilePicker.platform.pickFiles();
      // if (result != null) {
      //   return File(result.files.single.path!).readAsStringSync();
      // }
      return 'Loaded log content from file';
    },

    // Handle file opening
    onOpenFile: (path) async {
      await OpenFilex.open(path);
    },

    // Handle sharing
    onShare: (ISpectShareRequest request) async {
      final files = request.filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        files,
        text: request.text,
        subject: request.subject,
      );
    },
  ),
  child: child ?? const SizedBox.shrink(),
)
```

**Available callbacks:**
- `onLoadLogContent` – Load log files from storage
- `onOpenFile` – Open exported files with system viewers
- `onShare` – Share logs via system share sheet

**Useful packages:** [`file_picker`](https://pub.dev/packages/file_picker), [`open_filex`](https://pub.dev/packages/open_filex), [`share_plus`](https://pub.dev/packages/share_plus)

---

## Integrations

ISpect provides companion packages for common Flutter libraries.

### Available Packages

```yaml
dependencies:
  ispect: ^4.7.4              # Core package (required)
  ispectify_dio: ^4.7.4       # Dio HTTP client
  ispectify_http: ^4.7.4      # Standard http package
  ispectify_db: ^4.7.4        # Database operations
  ispectify_ws: ^4.7.4        # WebSocket traffic
  ispectify_bloc: ^4.7.4      # BLoC/Cubit integration
```

### 🌐 HTTP Monitoring

#### Dio

```dart
import 'package:dio/dio.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

ISpect.run(
  () => runApp(MyApp()),
  logger: logger,
  onInit: () {
    dio.interceptors.add(
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestData: true,
          printResponseData: true,
        ),
      ),
    );
  },
);
```

#### HTTP Package

```dart
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

ISpect.run(
  () => runApp(MyApp()),
  logger: logger,
  onInit: () {
    client.interceptors.add(
      ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
        ),
      ),
    );
  },
);
```

#### Multiple Clients

```dart
final Dio mainDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
final Dio uploadDio = Dio(BaseOptions(baseUrl: 'https://upload.example.com'));

ISpect.run(
  () => runApp(MyApp()),
  logger: logger,
  onInit: () {
    mainDio.interceptors.add(ISpectDioInterceptor(logger: logger));
    uploadDio.interceptors.add(ISpectDioInterceptor(logger: logger));
  },
);
```

### 🗄️ Database Integration

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

### 🔌 WebSocket Integration

```dart
import 'package:ws/ws.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

final interceptor = ISpectWSInterceptor(
  logger: logger,
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

### 🎯 BLoC Integration

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

ISpect.run(
  () => runApp(MyApp()),
  logger: logger,
  onInit: () {
    Bloc.observer = ISpectBlocObserver(
      logger: logger,
    );
  },
);
```

Filter specific BLoC logs:

```dart
final observer = ISpectNavigatorObserver();

ISpectBuilder(
  options: ISpectOptions(observer: observer),
  theme: const ISpectTheme(
    disabledLogTypes: {
      'bloc-event',
      'bloc-transition',
      'bloc-state',
    },
  ),
  child: child,
)
```

### 🧭 Navigation Tracking

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

Navigation events are logged with the `route` key.

---

### 🔒 Data Redaction

Sensitive data (tokens, passwords, API keys) is automatically redacted by default.

**Custom redaction:**

```dart
// HTTP / WebSocket
final redactor = RedactionService();
redactor.ignoreKeys(['authorization', 'x-api-key']);
redactor.ignoreValues(['<test-token>']);

// Database
ISpectDbCore.config = const ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
);

// Disable redaction (only for non-sensitive test data)
ISpectDioInterceptor(
  settings: const ISpectDioInterceptorSettings(
    enableRedaction: false,
  ),
);
```

---

## Examples

Check out the [example/](example/) directory for a complete working app with all integrations.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related Packages

- [ispectify](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify) – Core logging system
- [ispectify_dio](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_dio) – Dio integration
- [ispectify_http](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_http) – HTTP package integration
- [ispectify_ws](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_ws) – WebSocket monitoring
- [ispectify_db](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_db) – Database logging
- [ispectify_bloc](https://github.com/K1yoshiSho/ispect/tree/main/packages/ispectify_bloc) – BLoC integration

---

<div align="center">
  <p>Made with ❤️ for Flutter developers</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>