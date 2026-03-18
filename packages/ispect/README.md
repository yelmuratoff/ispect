<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

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

**ISpect** is a production-safe debugging toolkit for Flutter. It provides visual inspection, structured logging, network monitoring, and data redaction — all automatically removed from release builds via compile-time tree-shaking.

**[Live Web Demo](https://yelmuratoff.github.io/ispect/)** — drag and drop exported log files to explore them in the browser.

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/desktop.png?raw=true" width="700" />
</div>

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspector.png?raw=true" width="250" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/color_picker.png?raw=true" width="250" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/settings.png?raw=true" width="250" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/json_viewer.png?raw=true" width="250" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/share.png?raw=true" width="250" />
</div>

---

## Why ISpect?

Most Flutter debugging tools stay in your binary. ISpect doesn't — when `ISPECT_ENABLED` is not defined, the entire toolkit compiles to no-ops and is eliminated by Dart's tree-shaker. Zero bytes in production.

| Capability                | What it does                                                                 |
| ------------------------- | ---------------------------------------------------------------------------- |
| **Zero-footprint builds** | Compile-time `const` guard removes all code from release APK/IPA             |
| **Visual inspector**      | Tap any widget to see its render box, padding, constraints, and color        |
| **Structured logs**       | Typed log entries with levels, filtering, export/import, and session history |
| **Network capture**       | Request/response inspection for Dio, http, and WebSocket clients             |
| **Transaction grouping**  | Correlated request/response pairs with duration, status, and cross-navigation |
| **Automatic redaction**   | Tokens, passwords, PII, and credit cards masked before they reach logs       |
| **Observer hooks**        | Forward log events to Sentry, Crashlytics, or any backend in real-time       |
| **12 languages**          | en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi                               |

---

## Quick Start

```yaml
dependencies:
  ispect: ^4.8.0-dev08
```

```dart
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

void main() {
  ISpect.run(() => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers: ISpectNavigatorObserver.observers(),
      builder: (_, child) => ISpectBuilder.wrap(child: child!),
      home: const HomePage(),
    );
  }
}
```

```bash
# Development — toolkit active
flutter run --dart-define=ISPECT_ENABLED=true

# Release — toolkit removed via tree-shaking
flutter build apk
```

> When `ISPECT_ENABLED` is not set (default), `ISpect.run()`, `ISpectBuilder`, and `ISpectLocalizations.delegates()` become no-ops. Dart's tree-shaker strips everything out.

---

## Production Safety

Debug tools can expose API keys, tokens, and user data. ISpect solves this at the compiler level.

```bash
flutter build apk --release --obfuscate --split-debug-info=debug-info/
```

| Build                  | APK Size | "ispect" strings |
| ---------------------- | -------- | ---------------- |
| Obfuscated release     | 42.4 MB  | **6**            |
| Non-obfuscated release | 44.5 MB  | 34               |
| Development            | 51.0 MB  | 276              |

For environment-based control:

```dart
import 'package:flutter/foundation.dart';

class ISpectConfig {
  static const bool isEnabled = bool.fromEnvironment(
    'ISPECT_ENABLED',
    defaultValue: kDebugMode,
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get shouldInitialize => isEnabled && environment != 'production';
}

void main() {
  if (ISpectConfig.shouldInitialize) {
    ISpect.run(() => runApp(const MyApp()));
  } else {
    runApp(const MyApp());
  }
}
```

```bash
flutter build apk \
  --dart-define=ISPECT_ENABLED=true \
  --dart-define=ENVIRONMENT=staging
```

---

## Logger Configuration

```dart
void main() {
  final logger = ISpectFlutter.init(
    options: ISpectLoggerOptions(
      enabled: true,
      useHistory: true,
      useConsoleLogs: kDebugMode,
      maxHistoryItems: 5000,
      logTruncateLength: 4000,
    ),
  );

  ISpect.run(logger: logger, () => runApp(const MyApp()));
}
```

**Disable console output** (logs still flow to observers and UI):

```dart
ISpect.logger.configure(
  options: ISpect.logger.options.copyWith(useConsoleLogs: false),
);
```

**Streaming-only** (no in-memory history, useful for observer-driven pipelines):

```dart
final logger = ISpectFlutter.init(
  options: const ISpectLoggerOptions(useHistory: false),
);
```

**Filter by priority:**

```dart
class WarningsAndAbove implements ISpectFilter {
  @override
  bool apply(ISpectLogData data) {
    return (data.logLevel?.priority ?? 0) >= LogLevel.warning.priority;
  }
}

final logger = ISpectFlutter.init(filter: WarningsAndAbove());
```

---

## Localization

ISpect ships with 12 built-in locales. Pass delegates through `ISpectLocalizations.delegates()` — it merges ISpect's translations with your app's own delegates in a single call:

```dart
MaterialApp(
  localizationsDelegates: ISpectLocalizations.delegates(
    delegates: [
      // your app's delegates go here
    ],
  ),
)
```

To force a specific locale for the debug panel regardless of the app locale:

```dart
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    locale: const Locale('ru'),
  ),
  child: child ?? const SizedBox.shrink(),
)
```

---

## Observers

Observers tap into the log stream without coupling your app to ISpect's internals. Use them to bridge events to any external service.

```dart
class SentryISpectObserver implements ISpectObserver {
  @override
  void onLog(ISpectLogData data) {
    // Add as Sentry breadcrumb
  }

  @override
  void onError(ISpectLogData err) {
    // Sentry.captureException(err.exception, stackTrace: err.stackTrace);
  }

  @override
  void onException(ISpectLogData err) {
    // Sentry.captureException(err.exception, stackTrace: err.stackTrace);
  }
}

void main() {
  final logger = ISpectFlutter.init();
  logger.addObserver(SentryISpectObserver());

  ISpect.run(logger: logger, () => runApp(const MyApp()));
}
```

---

## Data Redaction

Sensitive data is automatically masked before it reaches logs or observers. Redaction is **enabled by default** in all network interceptors.

> **Note:** Network interceptors (`ISpectDioInterceptor`, `ISpectHttpInterceptor`, `ISpectWSInterceptor`) have `enableRedaction: true` by default. The built-in `SettingsBuilder.production()` and `SettingsBuilder.staging()` factory constructors also enable redaction automatically.

Built-in rules cover most common sensitive data: auth headers and tokens, passwords, API keys, cookies, PII (SSN, passport, driver's license), financial data (credit cards, bank accounts, IBAN), phone numbers, and more.

If a key is being redacted that you don't want masked (e.g., `?mobile=true` used as a platform flag, not a phone number), or you need to add your own sensitive keys — you can customize the `RedactionService`.

### Customizing RedactionService

Pass a configured `RedactionService` to the interceptor:

```dart
final redactor = RedactionService(
  // Add your own sensitive keys on top of the defaults
  sensitiveKeys: {
    ...kDefaultSensitiveKeys,
    'x-custom-secret',
    'internal_token',
  },

  // Add custom regex patterns for sensitive key detection
  sensitiveKeyPatterns: [
    RegExp(r'my_app_secret_\w+', caseSensitive: false),
  ],

  // Keys to fully mask (value replaced entirely with placeholder)
  fullyMaskedKeys: {'filename'},

  // Change the placeholder text (default: '[REDACTED]')
  placeholder: '***',

  // Number of characters visible at each edge of masked strings (default: 2)
  // e.g., "Bearer abc...xyz ([REDACTED])"
  stringEdgeVisible: 3,

  // Control binary and base64 redaction
  redactBinary: true,   // default: true
  redactBase64: true,    // default: true
);

ISpectDioInterceptor(
  redactor: redactor,
);
```

### Ignoring keys and values

If a default key is being redacted but shouldn't be in your context, pass `ignoredKeys` or `ignoredValues` in the constructor:

```dart
final redactor = RedactionService(
  // "mobile" won't be redacted (e.g., ?mobile=true for platform detection)
  ignoredKeys: {'mobile', 'platform_token'},
  // Specific values that should never be masked
  ignoredValues: {'<test-token>', 'public-api-key'},
);
```

You can also pass ignored keys/values per-call:

```dart
redactor.redact(
  data,
  ignoredKeys: {'mobile'},
  ignoredValues: {'public'},
);
```

### Disabling redaction

```dart
// Via settings
ISpectDioInterceptor(
  settings: const ISpectDioInterceptorSettings(enableRedaction: false),
);

// Via builder
final settings = ISpectDioInterceptorSettingsBuilder()
    .withoutRedaction()
    .build();
```

### Database-level redaction

```dart
ISpectDbCore.config = const ISpectDbConfig(
  redact: true,
  redactKeys: ['password', 'token', 'secret'],
);
```

---

## Modular Packages

Install only what your project needs. Each package works independently.

```yaml
dependencies:
  ispect: ^4.8.0-dev08 # Core UI, inspector, log viewer
  ispectify: ^4.8.0-dev08 # Logging backbone (Dart-only, no Flutter)
  ispectify_dio: ^4.8.0-dev08 # Dio HTTP interceptor
  ispectify_http: ^4.8.0-dev08 # http package interceptor
  ispectify_ws: ^4.8.0-dev08 # WebSocket traffic capture
  ispectify_db: ^4.8.0-dev08 # Database operation tracking
  ispectify_bloc: ^4.8.0-dev08 # BLoC event/state observer
```

### Dio

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

### http

```dart
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

final client = http_interceptor.InterceptedClient.build(interceptors: []);

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

### WebSocket

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
  WebSocketOptions.common(interceptors: [interceptor]),
);

interceptor.setClient(client);
```

### Database

```dart
import 'package:sqflite/sqflite.dart';
import 'package:ispectify_db/ispectify_db.dart';

ISpectDbCore.config = const ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  attachStackOnError: true,
  slowQueryThreshold: Duration(milliseconds: 400),
);

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

### BLoC

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

ISpect.run(
  () => runApp(MyApp()),
  logger: logger,
  onInit: () {
    Bloc.observer = ISpectBlocObserver(logger: logger);
  },
);
```

---

## Theming and Customization

```dart
ISpectBuilder(
  options: ISpectOptions(observer: observer),
  theme: ISpectTheme(
    pageTitle: 'Debug Panel',
    background: ISpectDynamicColor(light: Colors.white, dark: Colors.black),
    divider: ISpectDynamicColor(
      light: Colors.grey.shade300,
      dark: Colors.grey.shade800,
    ),
    logColors: {
      'error': Colors.red,
      'warning': Colors.orange,
      'info': Colors.blue,
      'debug': Colors.grey,
    },
    logIcons: {
      'error': Icons.error,
      'warning': Icons.warning,
      'info': Icons.info,
      'debug': Icons.bug_report,
    },
    logDescriptions: {
      'error': 'Critical application errors',
      'info': 'Informational messages',
    },
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
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    locale: const Locale('en'),
    actionItems: [
      ISpectActionItem(
        onTap: (context) { /* Clear cache, reset state */ },
        title: 'Clear All Data',
        icon: Icons.delete_sweep,
      ),
    ],
    panelItems: [
      DraggablePanelItem(
        enableBadge: false,
        icon: Icons.settings,
        onTap: (context) { /* Open settings */ },
      ),
    ],
    panelButtons: [
      DraggablePanelButtonItem(
        icon: Icons.info,
        label: 'App Info',
        onTap: (context) { /* Show app version */ },
      ),
    ],
  ),
  child: child ?? const SizedBox.shrink(),
)
```

### Settings Persistence

Load saved settings on startup and persist changes via `onSettingsChanged`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settingsJson = prefs.getString('ispect_settings');
  final initialSettings = settingsJson != null
      ? ISpectSettingsState.fromJson(jsonDecode(settingsJson))
      : null;

  final logger = ISpectFlutter.init();
  ISpect.run(logger: logger, () => runApp(MyApp(initialSettings: initialSettings)));
}

// In your widget:
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    initialSettings: initialSettings ?? const ISpectSettingsState(
      enabled: true,
      useConsoleLogs: true,
      useHistory: true,
    ),
    onSettingsChanged: (settings) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ispect_settings', jsonEncode(settings.toJson()));
    },
  ),
  child: child ?? const SizedBox.shrink(),
)
```

### Callbacks

```dart
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    onLoadLogContent: (context) async {
      // Load log files from storage via file_picker
      return 'Loaded log content';
    },
    onOpenFile: (path) async {
      // Open with system viewer via open_filex
    },
    onShare: (ISpectShareRequest request) async {
      // Share via share_plus
    },
  ),
  child: child ?? const SizedBox.shrink(),
)
```

### Navigation Tracking

```dart
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
      builder: (_, child) => ISpectBuilder(
        observer: _observer,
        child: child ?? const SizedBox(),
      ),
    );
  }
}
```

---

## Examples

See the [example/](example/) directory for a complete working app.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](../../CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
