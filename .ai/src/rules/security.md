# Security Rules

## Redaction

- Keep redaction enabled by default for network interceptors and database tracing.
- Use `RedactionService`, `NetworkMapRedactor`, `NetworkPayloadSanitizer`, and package config redaction keys instead of ad hoc masking.
- Add tests for sensitive headers, query parameters, request/response payloads, database args, and export/import paths when touching data capture.
- Preserve URL userInfo and query-parameter redaction in error messages and cURL/export helpers.

## Data Minimization

- Prefer metadata-only diagnostics before enabling body/header capture.
- Project database results to counts, IDs, durations, and status fields; avoid full row logging unless a caller explicitly supplies a redacted projection.
- Keep observer forwarding explicit and scoped by category.

## Production Safety

- Treat `ISPECT_ENABLED` as a compile-time internal-build flag, not a runtime feature switch.
- Public production build examples and CI release builds should omit `--dart-define=ISPECT_ENABLED=true`.
- If a change affects initialization, tree-shaking, or release footprint, run or account for the production-safety workflow behavior.

## Anti-Patterns

- Do not log tokens, cookies, passwords, API keys, phone numbers, financial fields, or raw PII.
- Do not weaken default sensitive key sets without a replacement and regression tests.
- Do not add secrets, `.env*`, certificates, or private keys to examples, tests, docs, or config.
