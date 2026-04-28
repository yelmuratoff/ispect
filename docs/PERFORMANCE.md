# Performance Scope

ISpect is intended for internal dev, QA, staging, dogfooding, and design-review builds. Runtime cost should be evaluated in that context.

## Disabled Builds

When `ISPECT_ENABLED` is omitted, ISpect entry points are inactive. The disabled path is known at compile time, so release builds are eligible for Dart tree-shaking of inactive toolkit code.

## Enabled Internal Builds

When ISpect is enabled for an internal build, overhead depends on what is captured:

- metadata-only logs are the lightest mode;
- request/response body capture costs more than metadata capture;
- database tracing cost depends on trace volume and result projection;
- high-volume BLoC/event streams should use filters;
- long sessions should use bounded history and export only the relevant window.

## Recommended Controls

- Start with the debug panel and metadata-only diagnostics.
- Enable payload/body capture only for targeted debugging.
- Use filters and sampling for noisy categories.
- Prefer result projection over full database rows.
- Keep history bounded for long QA sessions.

## Benchmarks

Public benchmark numbers should be added only when they are reproducible across the supported Flutter/Dart baseline. Until then, documentation should describe the performance model and recommended controls instead of claiming generic overhead numbers.
