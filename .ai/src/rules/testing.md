# Testing Rules

## Package Checks

- Run tests from the affected package directory; this repo does not use a root test runner.
- Use `flutter test --dart-define=ISPECT_ENABLED=true --coverage` for every package, including the pure Dart ones (`ispectify`, `ispectify_db`). The compile gate is required: without the define the suites fail to reach their assertions.
- Run `dart test --run-skipped test/production_safety_test.dart` without the define where that file exists — it asserts the disabled-build behavior.
- In `ispectify_db`, add `--no-pub`: the implicit resolution pulls in the example, whose `realm` dependency conflicts with `flutter_test`. Pair it with `dart pub get --no-example` first.
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
