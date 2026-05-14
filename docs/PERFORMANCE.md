# Performance Scope

ISpect runs inside internal builds. Runtime cost should be evaluated in that context, not against production traffic.

## Disabled builds

When `ISPECT_ENABLED` is omitted, every ISpect entry point is inactive. The disabled path is a compile-time constant, so release builds let Dart's tree-shaker drop the inactive toolkit code.

## Enabled internal builds

When the toolkit is on, overhead depends on what you capture:

- Metadata-only logs are the lightest mode.
- Request and response body capture is heavier than metadata, proportional to payload size.
- Database tracing cost scales with trace volume and result projection. Counts and IDs are cheap. Dumping full row contents is not.
- High-volume BLoC and event streams need filters or sampling.
- Long sessions need bounded history and exports limited to the relevant window.

## Controls

- Start with the debug panel and metadata-only diagnostics.
- Turn payload and body capture on for targeted debugging only.
- Filter or sample noisy categories.
- Prefer a result projection over a full database row.
- Keep the history bounded for long QA sessions.

## Benchmarks

There are no published benchmark numbers yet. They will appear when they are reproducible against the supported Flutter and Dart baseline. Until then, this document describes the performance model and the controls you can apply, not generic overhead numbers.
