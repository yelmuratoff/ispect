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

## Next: Integration Quality

- Improve observer examples for external sinks such as Sentry, Crashlytics, Grafana, and custom backends without presenting them as bundled official adapters.
- Add focused examples for common QA/staging rollout patterns.
- Expand database examples where wrappers already exist.
- Improve test fixtures for redaction, export/import, network correlation, and session history.
- Add stronger release-footprint reporting in CI.

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
