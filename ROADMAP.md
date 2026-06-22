# Roadmap

ISpect is on the `5.0.0-dev` line. The priority is to stabilize the 5.x architecture, documentation, release-safety checks, and the compatibility story before `5.0.0` ships as stable.

This roadmap is short on purpose. It describes the direction, not a promise that every imaginable integration ships in the next release.

## Now: 5.0 stabilization

- Harden production-safety checks for builds where `ISPECT_ENABLED` is omitted.
- Keep redaction on by default and expand coverage for realistic payloads.
- Document data handling, security, deprecations, compatibility, and release channels.
- Keep package READMEs generated from `docs/readme/`.
- Preserve package modularity so teams install only what they need.
- Keep analyzer and tests green against the pinned Flutter SDK used in CI.
- Keep positioning focused on internal builds.
- Complete publish dry-runs before cutting stable `5.0.0`.

## Next: integration quality

- Improve observer examples for internal tools, without presenting them as bundled production-telemetry adapters.
- Add focused examples for common QA and staging rollout patterns.
- Expand database examples where wrappers already exist.
- Improve test fixtures for redaction, export/import, network correlation, and session history.
- Add stronger release-footprint reporting in CI.
- Add a reproducible benchmark suite for startup cost, logging volume, export volume, history bounds, and payload capture on/off.
- Add real-world use cases or adoption notes when they can be published with concrete numbers, not invented ones.
- Decide whether the Dart and Flutter SDK baseline should stay as-is for 5.0 stable or whether a wider compatibility window is practical.

## Evidence before enterprise adoption

These are not required to use ISpect on internal builds, but they help larger teams trust the project:

- A stable `5.0.0` release after the dev validation line settles.
- Published benchmark methodology and results.
- A link from the docs to the production-safety CI result.
- Package publish dry-run results.
- At least two real internal QA or staging use cases.
- Migration examples for deprecated 5.x APIs.

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
