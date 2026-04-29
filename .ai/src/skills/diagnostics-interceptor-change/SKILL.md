---
name: diagnostics-interceptor-change
description: Use this skill when modifying ISpect network, WebSocket, database, BLoC, or trace logging behavior, including requests like "add capture", "fix redaction", "interceptor logs wrong data", "DB trace broken", "request IDs missing", or "payload should not leak". It preserves correlation IDs, redaction defaults, and package boundaries.
---

# Diagnostics Interceptor Change

Change diagnostic capture flows without breaking redaction, correlation, or package ownership.

## Steps

1. Identify the owning package:
   - Core trace/redaction/filter/history behavior: `packages/ispectify`
   - Dio adapter: `packages/ispectify_dio`
   - `http_interceptor` adapter: `packages/ispectify_http`
   - WebSocket adapter: `packages/ispectify_ws`
   - Database tracing: `packages/ispectify_db`
   - BLoC observer: `packages/ispectify_bloc`
2. Read the package root export and the current settings/config class before editing.
3. Preserve existing gates:
   - `settings.enabled`
   - `options.enabled`
   - sampling checks
   - `enableRedaction`
   - `kISpectEnabled` for app initialization paths
4. Preserve correlation metadata:
   - request/response/error flows should share request IDs.
   - DB transaction flows should use `ISpectDbTxn.currentTransactionId()` or explicit transaction IDs.
   - trace entries should use stable category, source, operation, target, duration, and meta fields.
5. Redact before logging or exporting structured data. Use existing redactors and constants instead of local masking.
6. Add tests for each changed path:
   - request, response, and error for network adapters.
   - success and error for DB/BLoC tracing.
   - enabled/disabled and redaction opt-out behavior when affected.
7. Run analyzer and tests for the owning package.

## Gotchas

- `ISpectLogType` is a `final class`, not an enum; do not use exhaustive enum switches or `values`.
- Per-call DB `redact: false` can differ from trace-level config redaction; tests should assert the intended layer.
- HTTP error responses are logged through `httpError` when status is 400-599; do not accidentally treat them as normal responses.
- Do not import another package's `src` files to reuse adapter internals.
