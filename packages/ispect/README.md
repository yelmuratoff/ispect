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
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/production_safety.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/production_safety.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Production%20Safety&labelColor=0360a9" alt="Production Safety workflow">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/test.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/test.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Test%20%26%20Analyze&labelColor=0360a9" alt="Test and Analyze workflow">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/deploy-web-logs-viewer.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/deploy-web-logs-viewer.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Web%20Demo%20Deploy&labelColor=0360a9" alt="Deploy Web Logs Viewer workflow">
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


<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/blob/benchmark-data/report.md">
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fyelmuratoff%2Fispect%2Fbenchmark-data%2Fbadge.json&style=for-the-badge" alt="Latest benchmark result">
  </a>
</div>

ISpect is a pre-release diagnostics toolkit for Flutter and Dart. It runs inside internal builds (developer machines, QA, staging) and gives testers and engineers a way to look at logs, network calls, database operations, BLoC events, navigation, and the widget tree without attaching a debugger. The toolkit is compile-time gated. Omit `--dart-define=ISPECT_ENABLED=true` and every entry point becomes a `const`-guarded no-op that Dart's tree-shaker can drop from release builds.

[Live web demo](https://yelmuratoff.github.io/ispect/). Drop an exported log file in to walk through a session in the browser.

## Start here

Add the Flutter panel, paste this setup, and run an internal build. It is the
smallest complete `ispect` integration: guarded startup, in-app panel, and
navigation diagnostics.

```yaml
dependencies:
  ispect: ^6.1.3
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

void main() => ISpect.run(() => runApp(const MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _observer = ISpectNavigatorObserver();

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          ...ISpectLocalizations.delegate(),
        ],
        navigatorObservers: ISpectNavigatorObserver.observers(
          observer: _observer,
        ),
        builder: (_, child) => ISpectBuilder.wrap(
          child: child!,
          options: ISpectOptions(observer: _observer),
        ),
        home: const Scaffold(body: Center(child: Text('My app'))),
      );
}
```

```bash
# Internal build: diagnostics active.
flutter run --dart-define=ISPECT_ENABLED=true

# Public release: omit the flag so the toolkit is inactive.
flutter build apk
```

### Choose the package you need

| Need                                            | Package                             |
| ----------------------------------------------- | ----------------------------------- |
| Structured logging only, with no Flutter UI     | `ispectify`                         |
| In-app panel, navigator observer, and inspector | `ispect`                            |
| Dio or `http` requests                          | `ispectify_dio` or `ispectify_http` |
| WebSocket frames                                | `ispectify_ws`                      |
| Database or storage operations                  | `ispectify_db`                      |
| BLoC/Cubit lifecycle                            | `ispectify_bloc`                    |
| Riverpod provider lifecycle                     | `ispectify_riverpod`                |
| Layout inspection only                          | `ispect_layout`                     |

Each adapter depends on `ispectify`; add `ispect` only when the Flutter UI is
useful. See the package README for the focused setup.

### Focused runnable examples

The `ispect` showcase keeps one target per integration, alongside the full
`complex_example.dart` tour:

```bash
cd packages/ispect/example
flutter run -t lib/network/main.dart --dart-define=ISPECT_ENABLED=true
flutter run -t lib/ws/main.dart --dart-define=ISPECT_ENABLED=true
flutter run -t lib/db/main.dart --dart-define=ISPECT_ENABLED=true
flutter run -t lib/bloc/main.dart --dart-define=ISPECT_ENABLED=true
flutter run -t lib/riverpod/main.dart --dart-define=ISPECT_ENABLED=true
flutter run -t lib/routing/main.dart --dart-define=ISPECT_ENABLED=true
```

The standalone BLoC and Riverpod observer examples run without Flutter:

```bash
cd packages/ispectify_bloc/example && dart run -DISPECT_ENABLED=true main.dart
cd packages/ispectify_riverpod/example && dart run -DISPECT_ENABLED=true main.dart
```

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
    <td align="center" width="34%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/performance.png?raw=true" width="240" alt="Performance overlay" /><br />
      <sub><strong>Performance overlay</strong><br />Live frame misses and dropped-frame counts.</sub>
    </td>
  </tr>
</table>

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/http_composer.png?raw=true" width="240" alt="HTTP composer" />
  <p><em>HTTP composer — replay a captured request or build one from scratch, then send it through your registered client.</em></p>
</div>

<table>
  <tr>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/text.png?raw=true" width="180" alt="Typography inspector" /><br />
      <sub><strong>Typography</strong><br />Style, scaler, and overflow.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/rich_text.png?raw=true" width="180" alt="Rich text inspector" /><br />
      <sub><strong>Rich text</strong><br />Span-by-span style breakdown.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/borders.png?raw=true" width="180" alt="Borders and radii inspector" /><br />
      <sub><strong>Borders &amp; radii</strong><br />Per-side borders and corner formatting.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/gradient.png?raw=true" width="180" alt="Gradient inspector" /><br />
      <sub><strong>Gradients</strong><br />Stops, <code>begin</code>/<code>end</code>, tile mode.</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/dark_gradient.png?raw=true" width="180" alt="Dark theme gradient inspector" /><br />
      <sub><strong>Dark themes</strong><br />Decoration against dark backgrounds.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/shadow_blur.png?raw=true" width="180" alt="Shadow and blur inspector" /><br />
      <sub><strong>Shadows &amp; blur</strong><br />Box shadows and backdrop filters.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/network_image.png?raw=true" width="180" alt="Network image inspector" /><br />
      <sub><strong>Images</strong><br />Source, raw pixels, fit, and alignment.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/rotated_box.png?raw=true" width="180" alt="Transform and clip inspector" /><br />
      <sub><strong>Transform &amp; clip</strong><br />Matrix decomposition and clip shape.</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/compare.png?raw=true" width="180" alt="Compare two widgets" /><br />
      <sub><strong>Compare</strong><br />Pixel gaps between two widgets.</sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/inspect/zoom.png?raw=true" width="180" alt="Zoom magnifier overlay" /><br />
      <sub><strong>Zoom</strong><br />Pixel-level magnifier overlay.</sub>
    </td>
  </tr>
</table>

## What it covers

The toolkit handles the diagnostics most projects rebuild by hand for every new app.

| Capability        | What it does                                                                                                                                                                                                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Release gating    | `kISpectEnabled` is a compile-time constant. Disabled builds tree-shake the toolkit out, so production binaries do not carry it.                                                                                                                                             |
| Debug panel       | Draggable in-app overlay with the log viewer, custom actions, and badges.                                                                                                                                                                                                    |
| Widget inspector  | Tap a widget to read its render box, decoration, constraints, padding, transforms, and text style.                                                                                                                                                                           |
| Structured logs   | Typed entries with severity, log-type keys, filters, bounded history, and JSON export/import.                                                                                                                                                                                |
| Network capture   | Request/response/error capture for Dio, the `http` package, and WebSocket clients. Requests and responses are paired by correlation ID.                                                                                                                                      |
| HTTP composer     | Replay a captured request or build one from scratch and send it through your registered `Dio`/`http` client, reusing its base URL, auth interceptors, and retries. Opt in with `ISpect.registerSender`; redacted values are re-added by the client at send time, not resent. |
| Database tracing  | One `dbTrace` extension wraps any storage call with timing, redaction, optional sampling, and a slow-query threshold.                                                                                                                                                        |
| BLoC observer     | Events, transitions, state changes, errors, and create/close hooks routed through the log pipeline.                                                                                                                                                                          |
| Riverpod observer | Provider add, update, dispose, and failure events routed through the log pipeline with the same redaction surface.                                                                                                                                                           |
| Redaction         | Auth headers, tokens, passwords, PII, and financial data masked before they reach logs, exports, observers, or the cURL helper.                                                                                                                                              |
| Observer hooks    | Forward selected log categories to your own sink through an `ISpectObserver` adapter.                                                                                                                                                                                        |
| Localization      | 14 UI languages: en, ru, kk, zh, es, fr, de, pt, ar, ko, ja, hi, ckb, ku.                                                                                                                                                                                                    |

## Compared to the obvious alternatives

| Tool                    | What it does well                                                            | Where ISpect fits                                                                                                                   |
| ----------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Flutter DevTools        | Profiling, memory, CPU, debugger, widget inspector when the IDE is attached. | DevTools needs an IDE connection. ISpect runs inside the app and lets a QA build export a session for offline inspection.           |
| Sentry, Crashlytics     | Production crash reporting, release health, alerts, retention.               | ISpect captures detail before the app ships. It is not a production telemetry replacement.                                          |
| Per-client interceptors | Logging request bodies to the console.                                       | ISpect correlates network, logs, database calls, BLoC events, and navigation in one viewer that shares a single redaction pipeline. |

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
4. Add network, database, BLoC, and Riverpod modules one at a time as you need them.
5. Leave body and header capture off until a payload-level investigation needs it.
6. Add your project's redaction keys before sharing exported sessions with anyone outside the team.

### Rolling file history (opt-in)

Internal Flutter builds can keep a bounded, daily history across app launches:

```dart
final logger = ISpectFlutter.init(
  options: ISpectLoggerOptions(maxHistoryItems: 10_000),
  fileHistory: const FileLogHistoryOptions(
    maxSessionDays: 7,
    maxFileSize: 5 * 1024 * 1024,
    maxTotalSize: 50 * 1024 * 1024,
  ),
);

ISpect.run(() => runApp(const App()), logger: logger);
```

`RollingFileLogHistory` writes redacted JSON Lines to the application cache, rotates segments by their actual UTF-8 size, and bounds both retained days and total disk usage. Existing 4.x `logs_YYYY-MM-DD.json` files remain readable. `ISpectFlutter.init(fileHistory: ...)` falls back to normal in-memory history on web, and creates no directory, timer, or file when `ISPECT_ENABLED` is omitted.

Passing `fileHistory:` above is all it takes: the log viewer then automatically surfaces a **Daily Sessions** browser — reachable from the settings sheet or by tapping the app-bar title — where each retained day reopens in the same viewer for browsing and search. The browser appears whenever `ISpect.logger.fileLogHistory` is set; nothing else needs wiring. Optionally set `onOpenFile`/`onShare` on the builder's `ISpectOptions` to add open-in-file-manager and share buttons for those sessions.

Persistence activates only on non-web builds run with `--dart-define=ISPECT_ENABLED=true` (see [Production safety](#production-safety)); otherwise the file history stays inert.

The global redaction switch remains authoritative. Setting `ISpectRedaction.enabled = false` while file history is configured deliberately allows raw values to be persisted. Keep it enabled unless an isolated internal investigation explicitly requires unredacted diagnostics.

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package                                                             | What it does                                                                                    |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`ispect`](https://pub.dev/packages/ispect)                         | Flutter UI: debug panel, log viewer, navigation observer, inspector integration.                |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout)           | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify)                   | Pure-Dart logging core: typed log entries, filtering, tracing, observers.                       |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio)           | Dio HTTP interceptor with automatic redaction.                                                  |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http)         | `http` package interceptor with automatic redaction.                                            |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws)             | Provider-agnostic WebSocket capture (any client) with automatic redaction.                      |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db)             | Database operation tracing for SQL, ORMs, and KV stores.                                        |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc)         | BLoC event, state, transition, and error observer.                                              |
| [`ispectify_riverpod`](https://pub.dev/packages/ispectify_riverpod) | Riverpod provider add, update, dispose, and failure observer.                                   |


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

- [AI integration prompt](https://github.com/yelmuratoff/ispect/blob/main/docs/prompt.md) — paste into any AI assistant to add ISpect for you
- [Security and data handling](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md)
- [Compatibility policy](https://github.com/yelmuratoff/ispect/blob/main/docs/COMPATIBILITY.md)
- [Deprecations and migration notes](https://github.com/yelmuratoff/ispect/blob/main/docs/DEPRECATIONS.md)
- [Quality gates](https://github.com/yelmuratoff/ispect/blob/main/docs/QUALITY.md)
- [Performance scope](https://github.com/yelmuratoff/ispect/blob/main/docs/PERFORMANCE.md)
- [Use cases](https://github.com/yelmuratoff/ispect/blob/main/docs/USE_CASES.md)
- [Integration walkthroughs](https://github.com/yelmuratoff/ispect/blob/main/docs/INTEGRATION_GUIDES.md)
- [Roadmap](https://github.com/yelmuratoff/ispect/blob/main/ROADMAP.md)

## Performance scope

The latest reproducible AOT hot-path and Android release-footprint data is
published in [`benchmark-data`](https://github.com/yelmuratoff/ispect/blob/benchmark-data/report.md).
Startup and frame timing require a recorded physical-device profile pass and
are not claimed by the current report. See [Performance
scope](https://github.com/yelmuratoff/ispect/blob/main/docs/PERFORMANCE.md)
for the measurement method and controls.

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
