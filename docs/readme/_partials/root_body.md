<!-- partial:header -->

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

| Capability | What it does |
| --- | --- |
| Release gating | `kISpectEnabled` is a compile-time constant. Disabled builds tree-shake the toolkit out, so production binaries do not carry it. |
| Debug panel | Draggable in-app overlay with the log viewer, custom actions, and badges. |
| Widget inspector | Tap a widget to read its render box, decoration, constraints, padding, transforms, and text style. |
| Structured logs | Typed entries with severity, log-type keys, filters, bounded history, and JSON export/import. |
| Network capture | Request/response/error capture for Dio, the `http` package, and WebSocket clients. Requests and responses are paired by correlation ID. |
| HTTP composer | Replay a captured request or build one from scratch and send it through your registered `Dio`/`http` client, reusing its base URL, auth interceptors, and retries. Opt in with `ISpect.registerSender`; redacted values are re-added by the client at send time, not resent. |
| Database tracing | One `dbTrace` extension wraps any storage call with timing, redaction, optional sampling, and a slow-query threshold. |
| BLoC observer | Events, transitions, state changes, errors, and create/close hooks routed through the log pipeline. |
| Riverpod observer | Provider add, update, dispose, and failure events routed through the log pipeline with the same redaction surface. |
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
4. Add network, database, BLoC, and Riverpod modules one at a time as you need them.
5. Leave body and header capture off until a payload-level investigation needs it.
6. Add your project's redaction keys before sharing exported sessions with anyone outside the team.

<!-- partial:install_matrix -->

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
- [Roadmap](https://github.com/yelmuratoff/ispect/blob/main/ROADMAP.md)

## Performance scope

Disabled builds are inactive at compile time, so there is nothing to benchmark when the flag is omitted. When the toolkit is on, cost depends on what you turn on. Metadata logging is the lightest mode. Body capture and database tracing add per-call work proportional to payload size. High-volume BLoC or event streams may need filters or sampling. There are no published benchmark numbers yet, and there will not be any until they are reproducible against the SDK baseline.

## Quick start

> **Prefer to let an AI wire it up?** If you are unsure how to integrate ISpect, copy the ready-made prompt at [`docs/prompt.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/prompt.md) and paste it into any AI coding assistant (Claude Code, Cursor, Copilot, etc.). It instructs the agent to read the current sources and add ISpect correctly and efficiently — initialization, route observer, network/database/state-management tracing, settings, and the share/open-file callbacks — scoped to what your project actually uses.

```yaml
dependencies:
  ispect: ^{{version}}
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

Per-client guides (Dio, `http`, WebSocket, DB, BLoC, Riverpod, layout inspector) live in the individual package READMEs linked in the table above.

<!-- partial:production_safety -->

## Repository

This is a monorepo. Every package above plus the standalone web log viewer lives in the same tree, with shared scripts for versioning, publishing, and doc sync. See [`bash/README.md`](https://github.com/yelmuratoff/ispect/blob/main/bash/README.md) for the automation stack and [`docs/VERSION_MANAGEMENT.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/VERSION_MANAGEMENT.md) for the release workflow.

## Documentation workflow

Package READMEs are generated. Sources live in `docs/readme/<package>.md` and shared fragments in `docs/readme/_partials/`. Run `./bash/build_readme.sh` to regenerate, and `./bash/build_readme.sh --check` in CI to catch drift. Hand-edits to `packages/*/README.md` get overwritten on the next build.

<!-- partial:footer -->
