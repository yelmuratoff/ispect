# Roadmap

ISpect is in the `5.0.0-dev` pre-release line. The priority is to stabilize the 5.x architecture, documentation, release-safety checks, and compatibility story before publishing `5.0.0` as stable.

This roadmap is intentionally selective. It describes direction without implying that every possible integration is part of the next release.

## Now: 5.0 Stabilization

- Harden production-safety checks for builds where `ISPECT_ENABLED` is omitted.
- Keep redaction enabled by default and expand coverage for realistic payloads.
- Document data-handling, security, deprecations, compatibility, and release channels.
- Keep package README files generated from `docs/readme/`.
- Preserve package modularity so teams install only what they need.
- Keep analyzer and tests green across the pinned Flutter SDK used in CI.
- Keep positioning focused on internal dev, QA, staging, dogfooding, and design-review builds.
- Complete publish dry-runs before cutting the stable `5.0.0` release.

## Next: Integration Quality

- Improve observer examples for internal tools without presenting them as bundled official production-telemetry adapters.
- Add focused examples for common QA/staging rollout patterns.
- Expand database examples where wrappers already exist.
- Improve test fixtures for redaction, export/import, network correlation, and session history.
- Add stronger release-footprint reporting in CI.
- Add a reproducible benchmark suite for startup, logging volume, export volume, history bounds, and payload capture on/off.
- Add real-world use cases or adoption notes when they can be published without inventing numbers.
- Review whether the Dart/Flutter SDK baseline should stay as-is for 5.0 stable or whether a wider compatibility window is practical.

## Evidence Before Enterprise Adoption

These items are not required to use ISpect in internal pre-release builds, but they improve trust for larger teams:

- stable `5.0.0` release after the dev validation line settles;
- published benchmark methodology and results;
- production-safety CI result linked from documentation;
- package publish dry-run results;
- at least two real internal QA/staging use cases;
- concise migration examples for deprecated 5.x APIs.

## Later: Optional Integrations

Potential integrations are evaluated only when there is clear demand and a maintainable API surface:

- GraphQL clients;
- gRPC clients;
- Riverpod observer;
- GoRouter and AutoRoute navigation diagnostics;
- Firebase and Supabase wrappers;
- analytics and crash-reporting breadcrumbs;
- push notification diagnostics;
- cache and background-task diagnostics.

## Not Goals

- Replacing Flutter DevTools profiling/debugger workflows.
- Replacing production telemetry platforms such as Sentry or Crashlytics.
- Capturing all application data by default.
- Shipping every ecosystem integration in the core package.
