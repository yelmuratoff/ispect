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


ISpect is a pre-release diagnostics toolkit for Flutter and Dart. It runs inside internal builds (developer machines, QA, staging) and gives testers and engineers a way to look at logs, network calls, database operations, BLoC events, navigation, and the widget tree without attaching a debugger. The toolkit is compile-time gated. Omit `--dart-define=ISPECT_ENABLED=true` and every entry point becomes a `const`-guarded no-op that Dart's tree-shaker can drop from release builds.

[Live web demo](https://yelmuratoff.github.io/ispect/). Drop an exported log file in to walk through a session in the browser.

## Preview

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/desktop.png?raw=true" width="760" alt="ISpect desktop log viewer" />
  <p><em>Desktop log viewer and standalone web demo.</em></p>
</div>

<table>
  <tr>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspector.png?raw=true" width="240" alt="Inspector panel" /><br />
      <sub><strong>Inspector</strong><br />Render tree, layout, spacing, transforms.</sub>
    </td>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/color_picker.png?raw=true" width="240" alt="Color picker" /><br />
      <sub><strong>Color picker</strong><br />Read on-screen colors and compare values.</sub>
    </td>
    <td align="center" width="34%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/json_viewer.png?raw=true" width="240" alt="JSON viewer" /><br />
      <sub><strong>JSON viewer</strong><br />Inspect structured payloads without leaving the app.</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/settings.png?raw=true" width="240" alt="Settings panel" /><br />
      <sub><strong>Settings</strong><br />Tune filters, history, and debug flags.</sub>
    </td>
    <td align="center" width="33%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/share.png?raw=true" width="240" alt="Share sheet" /><br />
      <sub><strong>Export and share</strong><br />Send sessions and logs for debugging or QA.</sub>
    </td>
    <td align="center" width="34%"></td>
  </tr>
</table>

<details>
  <summary><strong>Mobile screenshots</strong></summary>
  <br />
  <div align="center">
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

## What it covers

The toolkit handles the diagnostics most projects rebuild by hand for every new app.

| Capability | What it does |
| --- | --- |
| Release gating | `kISpectEnabled` is a compile-time constant. Disabled builds tree-shake the toolkit out, so production binaries do not carry it. |
| Debug panel | Draggable in-app overlay with the log viewer, custom actions, and badges. |
| Widget inspector | Tap a widget to read its render box, decoration, constraints, padding, transforms, and text style. |
| Structured logs | Typed entries with severity, log-type keys, filters, bounded history, and JSON export/import. |
| Network capture | Request/response/error capture for Dio, the `http` package, and WebSocket clients. Requests and responses are paired by correlation ID. |
| Database tracing | One `dbTrace` extension wraps any storage call with timing, redaction, optional sampling, and a slow-query threshold. |
| BLoC observer | Events, transitions, state changes, errors, and create/close hooks routed through the log pipeline. |
| Redaction | Auth headers, tokens, passwords, PII, and financial data masked before they reach logs, exports, observers, or the cURL helper. |
| Observer hooks | Forward selected log categories to your own sink through an `ISpectObserver` adapter. |
| Localization | 12 UI languages: en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi. |

## Compared to the obvious alternatives

| Tool | What it does well | Where ISpect fits |
| --- | --- | --- |
| Flutter DevTools | Profiling, memory, CPU, debugger, widget inspector when the IDE is attached. | DevTools needs an IDE connection. ISpect runs inside the app and lets a QA build export a session for offline inspection. |
| Sentry, Crashlytics | Production crash reporting, release health, alerts, retention. | ISpect captures detail before the app ships. It is not a production telemetry replacement. |
| Per-client interceptors | Logging request bodies to the console. | ISpect correlates network, logs, database calls, BLoC events, and navigation in one viewer that shares a single redaction pipeline. |

## Data handling

ISpect only captures what you enable. Logs, network metadata, optional bodies and headers, database trace arguments, BLoC events, navigation, and exports are all opt-in at the call site.

Redaction is on by default for every supported network and database interceptor. The shared engine masks auth headers, cookies, bearer tokens, passwords, API keys, common PII (emails, phone numbers, SSN-class IDs), and financial fields. Application-specific keys (tenant IDs, internal tokens, account numbers) live in your `RedactionService` configuration, because only your team knows what counts as sensitive in your data model.

The same redactor runs across every boundary that can leak. Interceptors, log export, clipboard helpers, cURL generation, and observer payloads all pass through it. A request masked in the viewer is also masked in the exported session, the cURL you paste into a ticket, and the payload an observer ships to an internal sink.

A few habits that pay off on shared internal builds:

- Capture metadata first. Turn body and header logging on only for the bug you are chasing.
- Register your domain-specific redaction keys before sharing exported sessions outside the engineering team.
- Treat exported `.json` sessions according to the data class they contain. They are plain-text artifacts and travel through the same channels as any internal log.
- Review observer adapters before pointing them at a centralized sink. An observer sees whatever category you choose to forward.
- Keep release pipelines free of `--dart-define=ISPECT_ENABLED=true`. The flag is the only thing that turns the toolkit on.

`docs/SECURITY.md` has the full data-handling policy and a rollout checklist.

## Minimal safe setup

Start with the UI shell and metadata-only diagnostics. Turn deeper capture on for the specific problem you are investigating.

1. Add `ispect` and wrap the app with `ISpect.run(...)` and `ISpectBuilder.wrap(...)`.
2. Run internal builds with `--dart-define=ISPECT_ENABLED=true`.
3. Keep production jobs free of that flag.
4. Add network, database, and BLoC modules one at a time as you need them.
5. Leave body and header capture off until a payload-level investigation needs it.
6. Add your project's redaction keys before sharing exported sessions with anyone outside the team.

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI: debug panel, log viewer, navigation observer, inspector integration. |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core: typed log entries, filtering, tracing, observers. |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction. |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction. |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | WebSocket traffic capture with automatic redaction. |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing for SQL, ORMs, and KV stores. |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event, state, transition, and error observer. |


## Release channel

The `5.x` line is the current stable channel and is the recommended pin for new integrations. If your dependency policy still requires the older API surface, the latest 4.x release remains available on pub.dev.

## Project state

What you can verify from the repository today:

- The current line is `5.x` stable. 4.x stable is still available on pub.dev for teams that need it.
- SDK baseline is Dart `>=3.6.0 <4.0.0`. Flutter packages are tested against the pinned Flutter SDK in CI, and the latest stable channel runs as an advisory signal.
- A `production_safety` CI job builds a release APK without `ISPECT_ENABLED` and counts residual `"ispect"` strings in the binary.
- Network capture, export, clipboard, cURL generation, and observer boundaries share the same `RedactionService`.
- Deprecations come with replacements and removal targets in `docs/DEPRECATIONS.md`.

Linked policies:

- [Security and data handling](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md)
- [Compatibility policy](https://github.com/yelmuratoff/ispect/blob/main/docs/COMPATIBILITY.md)
- [Deprecations and migration notes](https://github.com/yelmuratoff/ispect/blob/main/docs/DEPRECATIONS.md)
- [Quality gates](https://github.com/yelmuratoff/ispect/blob/main/docs/QUALITY.md)
- [Performance scope](https://github.com/yelmuratoff/ispect/blob/main/docs/PERFORMANCE.md)
- [Use cases](https://github.com/yelmuratoff/ispect/blob/main/docs/USE_CASES.md)
- [Roadmap](https://github.com/yelmuratoff/ispect/blob/main/ROADMAP.md)

## Performance scope

Disabled builds are inactive at compile time, so there is nothing to benchmark when the flag is omitted. When the toolkit is on, cost depends on what you turn on. Metadata logging is the lightest mode. Body capture and database tracing add per-call work proportional to payload size. High-volume BLoC or event streams may need filters or sampling. There are no published benchmark numbers yet, and there will not be any until they are reproducible against the SDK baseline.

## Quick start

```yaml
dependencies:
  ispect: ^5.2.0-dev.2
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

void main() {
  ISpect.run(() => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...ISpectLocalizations.delegate(),
      ],
      navigatorObservers: ISpectNavigatorObserver.observers(),
      builder: (_, child) => ISpectBuilder.wrap(child: child!),
      home: const HomePage(),
    );
  }
}
```

```bash
# Internal build, toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release build, toolkit inactive.
flutter build apk
```

Per-client guides (Dio, `http`, WebSocket, DB, BLoC, layout inspector) live in the individual package READMEs linked in the table above.

## Production safety

ISpect is flag-gated at compile time. When `ISPECT_ENABLED` is not defined, `ISpect.run()`, `ISpectBuilder.wrap(...)`, and `ISpectLocalizations.delegate()` resolve to `const`-guarded no-ops. Because the disabled path is a compile-time constant, release builds let Dart's tree-shaker drop the inactive toolkit code.

The flag is a build-time decision, not a runtime toggle. ISpect does not enable itself in production. A release pipeline opts in only if it explicitly passes `--dart-define=ISPECT_ENABLED=true`.

```bash
# Internal build, toolkit active.
flutter run --dart-define=ISPECT_ENABLED=true

# Release build, toolkit inactive.
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

- Keep production jobs free of `--dart-define=ISPECT_ENABLED=true`.
- Keep debug-only setup inside `ISpect.run(...)` and `ISpectBuilder.wrap(...)` entry points.
- Add an environment guard (`ENVIRONMENT != 'production'`) for internal staging builds that share the same pipeline as production.
- Check the generated artifact if your compliance process needs binary evidence.

Measured footprint on an obfuscated release APK built without `--dart-define=ISPECT_ENABLED`: 6 residual `"ispect"` strings, compared to 276 in a development build. Treat the number as a release-footprint sanity check, not a guarantee that every textual reference disappears from the binary.


## Repository

This is a monorepo. Every package above plus the standalone web log viewer lives in the same tree, with shared scripts for versioning, publishing, and doc sync. See [`bash/README.md`](https://github.com/yelmuratoff/ispect/blob/main/bash/README.md) for the automation stack and [`docs/VERSION_MANAGEMENT.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/VERSION_MANAGEMENT.md) for the release workflow.

## Documentation workflow

Package READMEs are generated. Sources live in `docs/readme/<package>.md` and shared fragments in `docs/readme/_partials/`. Run `./bash/build_readme.sh` to regenerate, and `./bash/build_readme.sh --check` in CI to catch drift. Hand-edits to `packages/*/README.md` get overwritten on the next build.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT. See [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
