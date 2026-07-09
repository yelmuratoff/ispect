# Roadmap

ISpect is on the `6.x` line (currently `6.0.5`). The 5.x architecture rollout — owned dark theme, hardened redaction pipeline, WASM support, pluggable log formatting — has shipped, and the core hardening pass (redaction coverage, docs, generated READMEs, CI gates, package modularity, release process) is complete. What remains is closing the evidence gaps before pitching ISpect to larger teams, and picking up new integrations if real demand shows up.

This roadmap is short on purpose. It describes the direction, not a promise that every imaginable integration ships in the next release.

## Next: optional file-based session history

`ispectify` already defines a `FileLogHistory` interface (`packages/ispectify/lib/src/history/file_log`) — daily file save/load, JSON import/export, cleanup, per-session lookup — and `ispect` already ships the browsing UI (`DailySessionsScreen`, per-day `LogsV2Screen`), wired through `ISpect.logger.fileLogHistory` and hidden automatically when it's absent. A concrete implementation shipped once (`DailyFileLogHistory`, 4.3.0) but did not carry over into the 5.x/6.x rewrite. What's missing is a first-party implementation to plug back in.

- Ship a concrete `FileLogHistory` in `ispectify`, opt-in via `ISpectFlutter.init(history: ...)` — not the default `ILogHistory` — matching the interface already in place.
- Support day-based grouping (what the interface already models via `getAvailableLogDates`/`getLogsByDate`) and evaluate explicit session-based grouping (`getLogsBySession` already anticipates non-daily boundaries, e.g. per app launch).
- Route every write through the same redaction pipeline as export (`RedactionService`/`LogExporter`) — `ISpectLogData.toJson()` does not redact by default, so a naive implementation would persist unredacted secrets to disk.
- Bound retention: wire `maxSessionDays`, `maxFileSize`, and a cleanup strategy (oldest-first, size-based, or archive — the `SessionCleanupStrategy` enum and `SessionStatistics` snapshot already exist but aren't connected to a live implementation) into `ISpectLoggerOptions`.
- Stay inert when `ISPECT_ENABLED` is omitted, same as the rest of the toolkit — no persisted session files in production builds.
- Add tests for redaction-on-write, rotation/cleanup boundaries, and the disabled-build no-op path.

## Evidence before enterprise adoption

Not required to use ISpect on internal builds, but these help larger teams trust the project:

- A reproducible benchmark suite and published results for startup cost, logging volume, export volume, history bounds, and payload capture on/off.
- At least two real internal QA or staging use cases, published with concrete numbers, not invented ones.

## Developer experience: onboarding and examples

The toolkit is broad, and the current entry points assume the reader already knows which pieces they need. Two things lower the barrier: a setup that cannot be copied wrong, and runnable examples split by the integration you actually care about.

### Onboarding

- Lead the root and `ispect` README sources (`docs/readme/*`) with a single copy-paste block that compiles as-is: `ISpect.run(() => runApp(...))`, the `ISpectBuilder` wrapper, one navigator observer, and the `--dart-define=ISPECT_ENABLED=true` run command. A public review recently reproduced a non-compiling `ISpect(child: ...)` setup — `ISpect` is a `final class` with a private constructor, not a widget — which is the signal that the current quick start does not land.
- Add a "which package do I need" decision table: logging only → `ispectify`; HTTP → `ispectify_dio` / `ispectify_http`; sockets → `ispectify_ws`; database/storage → `ispectify_db`; BLoC → `ispectify_bloc`; Riverpod → `ispectify_riverpod`; in-app panel and UI → `ispect`.
- Document the "just a logger" path explicitly so small projects can adopt `ispectify` alone, without the panel and observers — the toolkit does not have to be all-or-nothing.

### Examples split by category

Coverage is uneven today: `ispectify_db` and `ispectify_ws` already organize runnable variants under an `example/lib/examples/` subfolder, `ispectify_dio` / `ispectify_http` ship a single `main.dart`, and `ispectify_bloc` and `ispectify_riverpod` have no example project at all. The `ispect` showcase app already depends on every integration (its `complex_example.dart` demos Dio/HTTP/WS/DB plus Riverpod/BLoC observers in one file), so the split needs no new dependencies — it splits that combined tour into focused, category-first entry points:

```
packages/ispect/example/lib/
  network/main.dart      # Dio + http interceptors
  ws/main.dart           # WebSocket interceptor
  db/main.dart           # database/storage tracing
  bloc/main.dart         # BLoC observer
  riverpod/main.dart     # Riverpod observer
  routing/main.dart      # navigator observer (+ GoRouter/AutoRoute)
```

- Each entry point stays minimal and focused on one integration, runnable with `flutter run -t lib/<category>/main.dart`, so a reader opens exactly the example they need instead of the combined `complex_example.dart` tour (which stays as the "everything at once" reference).
- Seed the two missing standalone package examples first (`ispectify_bloc`, `ispectify_riverpod`) — a package with no example is the hardest to adopt.
- Add architecture-oriented walkthroughs (Clean Architecture layering, BLoC, Riverpod, GoRouter) showing where ISpect plugs into each layer — as documentation, not new abstractions in the packages. GoRouter/AutoRoute as navigation _diagnostics_ (beyond a plain integration example) stays under "Later: optional integrations".

### Inspector UI customization

Requests for "more inspector customization" are open-ended, and theming already exists. Before adding surface area, collect concrete asks (default filters, visible columns, panel layout) so the API grows against real call sites rather than speculative options.

## Later: optional integrations

Potential integrations land only when there is real demand and a maintainable API surface:

- GraphQL clients.
- gRPC clients.
- GoRouter and AutoRoute navigation diagnostics.
- Firebase and Supabase wrappers.
- Analytics and crash-reporting breadcrumbs.
- Push notification diagnostics.
- Cache and background-task diagnostics.

## Not goals

- Replacing Flutter DevTools profiling and debugger workflows.
- Replacing production telemetry platforms (Sentry, Crashlytics, and the rest).
- Capturing all application data by default.
- Shipping every ecosystem integration in the core package.
