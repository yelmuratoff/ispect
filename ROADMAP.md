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
