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

## TL;DR

Logging backbone: structured logs, filtering, history, export, redaction.

## 🏗️ Architecture

ISpectify serves as the logging foundation for the ISpect ecosystem:

| Component | Description |
|-----------|-----------|
| **Core Logger** | Based on Talker with enhanced features |
| **Log Filtering** | Advanced filtering and search capabilities |
| **Performance Tracking** | Built-in performance monitoring |
| **Export System** | Log export and analysis tools |
| **Integration Layer** | Seamless integration with ISpect toolkit |

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

## Logging Configuration

### Quick Flags (ISpectifyOptions)
| Option | Default | Effect | Use Case |
|--------|---------|--------|----------|
| enabled | true | Global on/off | Feature flag / release build |
| useConsoleLogs | true | Print to stdout | CI, local dev |
| useHistory | true | Keep in-memory history | Disable in load tests |
| maxHistoryItems | 10000 | Ring buffer size | Tune memory footprint |
| logTruncateLength | 10000 | Trim long console payloads | Prevent huge JSON spam |

### Disable Console Output
```dart
final logger = ISpectify(
  logger: ISpectifyLogger(
    settings: LoggerSettings(enableColors: false),
  ),
  options: ISpectifyOptions(useConsoleLogs: false),
);
```
Stdout stays clean; history + streams still work.

### Disable History (Stateless Mode)
```dart
final logger = ISpectify(options: ISpectifyOptions(useHistory: false));
```
No retention; stream subscribers still receive real-time logs. Memory overhead minimal.

### Minimal Footprint (CI / Benchmarks)
```dart
final logger = ISpectify(
  options: ISpectifyOptions(
    enabled: true,
    useConsoleLogs: true, // or false for JSON parsing scenarios
    useHistory: false,
    logTruncateLength: 400,
  ),
  logger: ISpectifyLogger(
    settings: LoggerSettings(
      enableColors: false, // deterministic output
      maxLineWidth: 80,
    ),
  ),
);
```

### Memory Control
Keep history bounded; large payloads are truncated before print: 
```dart
ISpectifyOptions(
  maxHistoryItems: 2000,
  logTruncateLength: 2000,
);
```

### Custom Titles & Colors
```dart
ISpectifyOptions(
  titles: { 'http-request': '➡ HTTP', 'http-response': '⬅ HTTP' },
  colors: { 'http-error': AnsiPen()..red(bg:true) },
);
```
Unknown keys fallback to the key string + gray pen.

### Dynamic Reconfigure (Hot)
```dart
final i = ISpectify(...);
// Later
i.configure(options: i.options.copyWith(useConsoleLogs: false));
```
Existing stream listeners unaffected. History retained unless `useHistory` becomes false (existing entries remain; future ones not stored).

### Filtering (Custom)
Provide a filter implementation to drop noise early: 
```dart
class OnlyErrorsFilter implements ISpectifyFilter {
  @override
  bool apply(ISpectifyData d) => d.logLevel?.priority >= LogLevel.error.priority;
}

final logger = ISpectify(filter: OnlyErrorsFilter());
```

### Route / Analytics / Provider Logs
Use dedicated helpers: `route('/home')`, `track('login', event: 'login')`, `provider('UserRepository created')`. Customize visibility at UI layer (ISpect theme) via `logDescriptions`.

### Disabling Print Hijack
When using `ISpect.run` set `isPrintLoggingEnabled: false` to leave `print()` untouched.
```dart
ISpect.run(
  () => runApp(App()),
  logger: logger,
  isPrintLoggingEnabled: false,
);
```

### Safe Production Pattern
Keep code tree-shaken out: 
```bash
flutter run --dart-define=ENABLE_ISPECT=true
flutter build apk # default false -> removed
```
```dart
const kEnable = bool.fromEnvironment('ENABLE_ISPECT');
if (kEnable) {
  ISpect.run(() => runApp(App()), logger: logger);
} else {
  runApp(App());
}
```

### Avoid Log Flood (Large JSON / Streams)
Pre-truncate before logging if payload > N: 
```dart
logger.debug(json.length > 2000 ? json.substring(0, 2000) + '…' : json);
```
Or adjust `logTruncateLength`.

### History Export (Pattern)
History object: 
```dart
final copy = logger.history; // List<ISpectifyData>
```
Serialize manually (avoid bundling secrets). Provide redaction upstream before logging.

### Toggle On-the-fly (Dev Tools)
Expose a switch: 
```dart
setState(() => logger.options.enabled = !logger.options.enabled);
```
Prefer a wrapper method to avoid direct state in UI tests.

### When to Disable History
- Long running integration tests
- GPU / memory profiling sessions
- High-frequency streaming (WS metrics)

### When to Disable Console
- Parsing machine-readable test output
- Prevent noise in CI logs
- Benchmark harness isolation

### Line Width vs Wrap
Use `maxLineWidth` to constrain horizontal noise; does not truncate content (truncation done via `logTruncateLength`). Set lower for narrow terminals.

### Color Strategy
Disable colors for: CI, log ingestion systems, snapshot testing. Keep colors locally for readability.

### Error / Exception Flow
`logger.handle(exception)` decides between `ISpectifyError` and `ISpectifyException`; observer callbacks fire before streaming. Provide a custom `ISpectifyErrorHandler` to rewrite classification.

### Zero-Allocation Path
For ultra hot loops avoid string interpolation before checking `options.enabled`. Pattern: 
```dart
if (logger.options.enabled) logger.debug(buildHeavyString());
```

### Thread / Zone Capturing
Use `ISpect.run` with `isZoneErrorHandlingEnabled` (default true) to automatically route uncaught zone errors through `logger.handle`. Disable if running inside another error aggregation framework.

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
  ispectify: ^4.4.0-dev06
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

### Minimal Setup

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

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispect](../ispect) - Main debugging interface
- [ispectify_dio](../ispectify_dio) - Dio HTTP client integration
- [ispectify_http](../ispectify_http) - Standard HTTP client integration
- [ispectify_db](../ispectify_db) - Database operation logging
- [ispectify_bloc](../ispectify_bloc) - BLoC state management integration

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>