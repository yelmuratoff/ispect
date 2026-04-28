<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/root.md
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


**ISpect** is an in-app observability and QA diagnostics toolkit for Flutter and Dart. It provides a visual debug panel, structured logging, network monitoring, database tracing, widget-tree inspection, and data redaction — with compile-time gating so the toolkit is inactive unless `ISPECT_ENABLED=true` is provided.

**[Live web demo](https://yelmuratoff.github.io/ispect/)** — drag and drop exported log files to explore them in the browser.

## Preview

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/desktop.png?raw=true" width="760" alt="ISpect desktop log viewer" />
  <p><em>Desktop log viewer and standalone web demo.</em></p>
</div>

<table>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspector.png?raw=true" width="240" alt="Inspector panel" /><br />
      <sub><strong>Inspector</strong><br />Render tree, layout, spacing, transforms.</sub>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/color_picker.png?raw=true" width="240" alt="Color picker" /><br />
      <sub><strong>Color picker</strong><br />Read on-screen colors and compare values.</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/json_viewer.png?raw=true" width="240" alt="JSON viewer" /><br />
      <sub><strong>JSON viewer</strong><br />Inspect structured payloads without leaving the app.</sub>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/share.png?raw=true" width="240" alt="Share sheet" /><br />
      <sub><strong>Export and share</strong><br />Send sessions and logs for debugging or QA.</sub>
    </td>
  </tr>
</table>

<details>
  <summary><strong>Mobile showcase</strong></summary>
  <br />
  <div align="center">
    <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/settings.png?raw=true" width="180" alt="Settings panel" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/1.jpg" width="180" alt="Typography inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/2.jpg" width="180" alt="Layout inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/3.jpg" width="180" alt="Spacing inspector on mobile" />
  </div>
  <br />
  <div align="center">
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/4.jpg" width="180" alt="Decoration inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/5.jpg" width="180" alt="Transform inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/6.jpg" width="180" alt="Effects inspector on mobile" />
    <img src="https://raw.githubusercontent.com/yelmuratoff/packages_assets/main/assets/ispect/7.jpg" width="180" alt="Alignment and margin inspector on mobile" />
  </div>
</details>

## Why ISpect?

ISpect is designed for the gap between local debugging and production telemetry: QA builds, staging builds, dogfooding, and support sessions where you need to inspect what happened inside the app without attaching a debugger. When `ISPECT_ENABLED` is not defined at compile time, ISpect entry points become `const`-guarded no-ops and are eligible for Dart tree-shaking.

| Capability               | What it does                                                                    |
| ------------------------ | ------------------------------------------------------------------------------- |
| **Release-gated builds** | Compile-time guard keeps the toolkit inactive unless explicitly enabled         |
| **Visual debug panel**   | Draggable overlay with custom actions, badges, and the log viewer               |
| **Widget inspector**     | Tap any widget to read its render box, decorations, constraints, and transforms |
| **Structured logs**      | Typed entries with levels, categories, filtering, history, and export/import    |
| **Network capture**      | Request / response / error capture for Dio, `http`, and WebSocket clients       |
| **Database tracing**     | Passive observability for any storage driver via a single `dbTrace` extension   |
| **BLoC observer**        | Event / state / transition / error forwarding into the log pipeline             |
| **Automatic redaction**  | Tokens, passwords, PII, and credit-card data masked before they reach logs      |
| **Observer hooks**       | Forward log events to your own Sentry, Crashlytics, Grafana, or backend adapter |
| **12 languages**         | en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi                                  |

## How it differs

| Tool                       | Best for                                                                    | Where ISpect fits                                                                                        |
| -------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Flutter DevTools           | Local profiling, widget inspection, memory, CPU, and debugger workflows     | ISpect runs inside QA/staging builds and can export a diagnostic session without a connected IDE         |
| Sentry / Crashlytics       | Production crash reporting, release health, alerts, and long-term telemetry | ISpect gives an interactive in-app log/session viewer before forwarding selected events elsewhere        |
| Dio interceptors / loggers | Request logs and console output                                             | ISpect correlates logs, network, database, BLoC, navigation, export, and visual inspection in one viewer |

## Data handling

ISpect can capture sensitive application data if you configure it to log request bodies, response bodies, database arguments, BLoC payloads, or custom messages. Redaction is enabled by default in the network packages and the shared redaction engine covers common auth headers, tokens, cookies, credentials, PII, and financial fields, but no automatic redactor can understand every domain-specific payload.

Before using ISpect in shared QA, staging, customer-support, or enterprise builds:

- keep body/header capture limited to what the team actually needs;
- add project-specific redaction keys for tenant IDs, internal tokens, account numbers, and business identifiers;
- treat exported sessions as sensitive files;
- review observer adapters before forwarding logs to Sentry, Crashlytics, Grafana, or custom backends;
- keep `ISPECT_ENABLED` disabled for production release builds unless you have an explicit internal policy for enabling it.

See [`docs/SECURITY.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md) for the data-handling policy and recommended rollout checklist.

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


## Release channel

The `5.0.0-dev` line is a pre-release channel for teams validating the upcoming 5.x architecture and package split. If your dependency policy allows only stable packages, pin a stable version from pub.dev until `5.0.0` is released.

## Project maturity

- [Security and data handling](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md)
- [Compatibility policy](https://github.com/yelmuratoff/ispect/blob/main/docs/COMPATIBILITY.md)
- [Deprecations and migration notes](https://github.com/yelmuratoff/ispect/blob/main/docs/DEPRECATIONS.md)
- [Quality gates](https://github.com/yelmuratoff/ispect/blob/main/docs/QUALITY.md)
- [Roadmap](https://github.com/yelmuratoff/ispect/blob/main/ROADMAP.md)

## Quick start

```yaml
dependencies:
  ispect: ^5.0.0-dev33
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

# Release — omit the flag so ISpect remains inactive.
flutter build apk
```

For package-specific guides (Dio, http, WS, DB, BLoC, layout inspector) see the individual package READMEs linked in the table above.

## Production safety

ISpect is flag-gated. When `ISPECT_ENABLED` is not defined at compile time, `ISpect.run()`, `ISpectBuilder`, and `ISpectLocalizations.delegates()` become `const`-guarded no-ops and are eligible for Dart's tree-shaker in release builds.

```bash
# Development — toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release — omit the flag so ISpect remains inactive.
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

Release checklist:

- do not pass `--dart-define=ISPECT_ENABLED=true` to production release jobs;
- keep debug-only setup inside `ISpect.run(...)` / `ISpectBuilder.wrap(...)` entry points;
- prefer environment-aware guards such as `ENVIRONMENT != 'production'` for internal staging builds;
- verify generated artifacts if your compliance process requires binary evidence.

Measured impact on an obfuscated release APK (no `--dart-define=ISPECT_ENABLED`): 6 residual `"ispect"` strings vs. 276 in a development build. Treat this as a release-footprint check, not a promise that every textual reference disappears from the binary.


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
