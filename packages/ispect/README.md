<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispect.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispect">
      <img src="https://img.shields.io/pub/v/ispect?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&labelColor=0360a9&color=2ab7f6" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=for-the-badge&logo=github&labelColor=0360a9&color=2ab7f6" alt="GitHub stars">
    </a>
    <a href="https://codecov.io/gh/yelmuratoff/ispect">
      <img src="https://img.shields.io/codecov/c/github/yelmuratoff/ispect?style=for-the-badge&logo=codecov&labelColor=0360a9&color=2ab7f6" alt="Coverage">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispect/score">
      <img src="https://img.shields.io/pub/likes/ispect?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect/score">
      <img src="https://img.shields.io/pub/points/ispect?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispect">
      <img src="https://img.shields.io/pub/dm/ispect?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


**ISpect** is a production-safe debugging toolkit for Flutter. It provides a visual debug panel, structured logging, network monitoring, and data redaction — all automatically stripped from release builds via compile-time tree-shaking.

**[Live web demo](https://yelmuratoff.github.io/ispect/)** — drag and drop exported log files to explore them in the browser.

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

## What's in the box

| Capability | What it does |
| --- | --- |
| Zero-footprint builds | Compile-time `const` guard removes all code from release APK/IPA |
| Draggable debug panel | Floating panel with quick actions, custom items, and badge notifications |
| Visual inspector | Tap any widget to see its render box, padding, constraints, and colours |
| Structured logs | Typed log entries with levels, filtering, export/import, and session history |
| Observer hooks | Forward log events to Sentry, Crashlytics, or any backend in real time |
| 12 languages | en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi |

For Dio/http/WS/DB/BLoC capture and the standalone layout inspector, see the [toolkit packages](#the-ispect-toolkit).

## Install

```yaml
dependencies:
  ispect: ^5.0.0-dev18
```

## Quick start

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
# Development — toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release — toolkit removed via tree-shaking.
flutter build apk
```

## Production safety

ISpect is flag-gated — with zero footprint in release builds when `ISPECT_ENABLED` is not defined at compile time. `ISpect.run()`, `ISpectBuilder`, and `ISpectLocalizations.delegates()` become `const`-guarded no-ops and Dart's tree-shaker eliminates the entire toolkit.

```bash
# Development — toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release — toolkit removed by the tree-shaker.
flutter build apk
```

For environment-aware control:

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
```

Measured impact on an obfuscated release APK (no `--dart-define=ISPECT_ENABLED`): 6 residual `"ispect"` strings vs. 276 in a development build. See [ispect on pub.dev](https://pub.dev/packages/ispect) for the full production-safety guide.


## Logger configuration

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

**Disable console output** (logs still flow to observers and the UI):

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

**Filter by log-type key** (suppress noisy categories without touching call sites):

```dart
final logger = ISpectFlutter.init(
  filter: ISpectFilter(logTypeKeys: {'analytics', 'route'}),
);
```

**Filter by severity** (drop `debug`/`verbose`, keep `info` and above):

```dart
final logger = ISpectFlutter.init(
  logger: ISpectBaseLogger(
    filter: LogLevelRangeFilter(minLevel: LogLevel.info),
  ),
);
```

## Localization

ISpect ships with 12 built-in locales. `ISpectLocalizations.delegates()` merges ISpect's translations with your own delegates in a single call:

```dart
MaterialApp(
  localizationsDelegates: ISpectLocalizations.delegates(
    delegates: [
      // your app's delegates go here
    ],
  ),
)
```

Force a specific locale regardless of the app locale:

```dart
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    locale: const Locale('ru'),
  ),
  child: child ?? const SizedBox.shrink(),
)
```

## Observers

Observers tap into the log stream without coupling your app to ISpect internals — use them to bridge events to any external service.

```dart
class SentryISpectObserver extends ISpectObserver {
  const SentryISpectObserver();

  @override
  void onLog(ISpectLogData data) {
    // Add as Sentry breadcrumb.
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
  logger.addObserver(const SentryISpectObserver());

  ISpect.run(logger: logger, () => runApp(const MyApp()));
}
```

## Theming

```dart
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    initialSettings: ISpectSettingsState(
      disabledLogTypes: {
        'riverpod-add',
        'riverpod-update',
        'riverpod-dispose',
        'riverpod-fail',
      },
    ),
  ),
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
  ),
  child: child ?? const SizedBox.shrink(),
)
```

## Panel actions and custom items

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

## Settings persistence

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

## Callbacks

```dart
ISpectBuilder(
  options: ISpectOptions(
    observer: observer,
    onLoadLogContent: (context) async {
      // Load log files from storage via file_picker.
      return 'Loaded log content';
    },
    onOpenFile: (path) async {
      // Open with the system viewer via open_filex.
    },
    onShare: (ISpectShareRequest request) async {
      // Share via share_plus.
    },
  ),
  child: child ?? const SizedBox.shrink(),
)
```

## Navigation tracking

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

## Security considerations

Exported log files (share, daily sessions) are stored as **plain-text JSON** on disk. Network traffic is redacted automatically (see the `ispectify_*` packages), but messages written via `ISpect.logger.info(...)` are stored as-is.

- **Never log PII** (emails, phone numbers, tokens, passwords) via `ISpect.logger.*`.
- Review redaction rules in your network interceptors to cover all sensitive headers and URL parameters.
- In production builds the toolkit is fully tree-shaken when `ISPECT_ENABLED` is unset, so no log files are created.
- For sensitive environments, clear daily sessions regularly or disable file logging.

## Example

See [example/](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect/example) for a complete working app.

## The ISpect toolkit

ISpect is a modular monorepo. Install only what your project needs — each package works independently.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI — debug panel, log viewer, navigation observer, inspector integration |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector — sizes, constraints, decorations, compare mode, color picker |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core — typed log entries, filtering, tracing, observers |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | WebSocket traffic capture with automatic redaction |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing (SQL, ORM, KV stores) |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event / state / transition observer |


## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT — see [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
