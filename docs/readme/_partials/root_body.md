<!-- partial:header -->

**ISpect** is a production-safe debugging toolkit for Flutter and Dart. It provides a visual debug panel, structured logging, network monitoring, database tracing, widget-tree inspection, and data redaction — all automatically stripped from release builds via compile-time tree-shaking.

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

<!-- partial:install_matrix -->

## Quick start

```yaml
dependencies:
  ispect: ^{{version}}
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

<!-- partial:production_safety -->

## Repository

This repository is a monorepo containing every package above plus a standalone web-based log viewer, with shared tooling for versioning, publishing, and doc sync. See [`bash/README.md`](https://github.com/yelmuratoff/ispect/blob/main/bash/README.md) for the automation stack and [`docs/VERSION_MANAGEMENT.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/VERSION_MANAGEMENT.md) for the release workflow.

## Documentation workflow

Each package README is generated from a per-package source in `docs/readme/`. Shared fragments (header, footer, install matrix, redaction block, production-safety block) live in `docs/readme/_partials/`. Regenerate with `./bash/build_readme.sh`; verify in CI with `./bash/build_readme.sh --check`. Do not edit `packages/*/README.md` by hand — edits are overwritten on the next build.

<!-- partial:footer -->
