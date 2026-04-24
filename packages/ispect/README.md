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


**ISpect** is a production-safe debugging toolkit for Flutter and Dart. It provides a visual debug panel, structured logging, network monitoring, database tracing, widget-tree inspection, and data redaction — all automatically stripped from release builds via compile-time tree-shaking.

**[Live web demo](https://yelmuratoff.github.io/ispect/)** — drag and drop exported log files to explore them in the browser.

## Preview

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/desktop.png?raw=true" width="760" alt="ISpect desktop log viewer" />
  <p><em>Desktop log viewer and standalone web demo.</em></p>
</div>

<table>
  <tr>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspector.png?raw=true" width="250" alt="Inspector panel" /><br />
      <sub><strong>Inspector</strong><br />Render tree, layout, spacing, transforms.</sub>
    </td>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/color_picker.png?raw=true" width="250" alt="Color picker" /><br />
      <sub><strong>Color picker</strong><br />Read on-screen colors and compare values.</sub>
    </td>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/settings.png?raw=true" width="250" alt="Settings panel" /><br />
      <sub><strong>Settings</strong><br />Toggle tools, filters, and debug behavior.</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/json_viewer.png?raw=true" width="250" alt="JSON viewer" /><br />
      <sub><strong>JSON viewer</strong><br />Inspect structured payloads without leaving the app.</sub>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/share.png?raw=true" width="250" alt="Share sheet" /><br />
      <sub><strong>Export and share</strong><br />Send sessions and logs for debugging or QA.</sub>
    </td>
  </tr>
</table>

<details>
  <summary><strong>Mobile showcase</strong></summary>
  <br />
  <div align="center">
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/1.jpg" width="180" alt="Typography inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/2.jpg" width="180" alt="Layout inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/3.jpg" width="180" alt="Spacing inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/4.jpg" width="180" alt="Decoration inspector on mobile" />
  </div>
  <br />
  <div align="center">
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/5.jpg" width="180" alt="Transform inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/6.jpg" width="180" alt="Effects inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/7.jpg" width="180" alt="Alignment and margin inspector on mobile" />
  </div>
</details>

## Why ISpect?

Most Flutter debug tooling ships in your binary. ISpect doesn't — when `ISPECT_ENABLED` isn't defined at compile time, the entire toolkit compiles to `const`-guarded no-ops and Dart's tree-shaker strips it from the release APK/IPA. Zero bytes in production.

| Capability | What it does |
| --- | --- |
| **Zero-footprint builds** | Compile-time guard removes all code from release builds |
| **Visual debug panel** | Draggable overlay with custom actions, badges, and the log viewer |
| **Widget inspector** | Tap any widget to read its render box, decorations, constraints, and transforms |
| **Structured logs** | Typed entries with levels, categories, filtering, history, and export/import |
| **Network capture** | Request / response / error capture for Dio, `http`, and WebSocket clients |
| **Database tracing** | Passive observability for any storage driver via a single `dbTrace` extension |
| **BLoC observer** | Event / state / transition / error forwarding into the log pipeline |
| **Automatic redaction** | Tokens, passwords, PII, and credit-card data masked before they reach logs |
| **Observer hooks** | Forward log events to Sentry, Crashlytics, or any backend in real time |
| **12 languages** | en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi |

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


## Quick start

```yaml
dependencies:
  ispect: ^5.0.0-dev24
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
# Development — toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release — toolkit removed via tree-shaking.
flutter build apk
```

For package-specific guides (Dio, http, WS, DB, BLoC, layout inspector) see the individual package READMEs linked in the table above.

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


## Repository

This repository is a monorepo containing every package above plus a standalone web-based log viewer, with shared tooling for versioning, publishing, and doc sync. See [`bash/README.md`](https://github.com/yelmuratoff/ispect/blob/main/bash/README.md) for the automation stack and [`docs/VERSION_MANAGEMENT.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/VERSION_MANAGEMENT.md) for the release workflow.

## Documentation workflow

Each package README is generated from a per-package source in `docs/readme/`. Shared fragments (header, footer, install matrix, redaction block, production-safety block) live in `docs/readme/_partials/`. Regenerate with `./bash/build_readme.sh`; verify in CI with `./bash/build_readme.sh --check`. Do not edit `packages/*/README.md` by hand — edits are overwritten on the next build.

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
