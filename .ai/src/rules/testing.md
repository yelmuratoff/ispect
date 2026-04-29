# Testing Rules

## Package Checks

- Run tests from the affected package directory; this repo does not use a root test runner.
- Use `dart test --coverage=coverage` for pure Dart packages: `ispectify` and `ispectify_db`.
- Use `flutter test --coverage` for Flutter packages: `ispect`, `ispect_layout`, `ispectify_dio`, `ispectify_http`, `ispectify_ws`, `ispectify_bloc`.
- Pair tests with `dart analyze --fatal-infos` or `flutter analyze --fatal-infos` for the same package.

## What To Test

- Cover redaction defaults, opt-outs, and stats when changing `RedactionService`, network payload processing, export, clipboard, or observer data.
- Cover request/response/error paths when changing Dio, http, WebSocket, or database interceptors.
- Cover disabled logging behavior when changing `options.enabled`, sampling, filters, or `kISpectEnabled` gates.
- For Flutter widgets, test visible state, callbacks, error boundaries, and localization-sensitive labels when behavior changes.

## Test Style

- Follow existing `package:test` and `flutter_test` patterns with `group`, `setUp`, and behavior-focused `test` names.
- Use `FakeLogger` or an in-memory `ISpectLogger` history assertion instead of real console output.
- Keep tests deterministic: no real network calls, no sleeps, no wall-clock assertions beyond controlled `Duration` values.

## Anti-Patterns

- Do not add broad snapshot-style tests for generated localization output.
- Do not test third-party clients directly; test the adapter's interaction with ISpect log entries and metadata.
- Do not leave coverage directories committed.
