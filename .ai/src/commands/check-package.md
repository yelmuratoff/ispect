---
description: Run the correct analyzer and tests for one ISpect package
argument-hint: "<package-name>"
---

Package: `$ARGUMENTS`

Determine whether `$ARGUMENTS` is a pure Dart package or Flutter package:

- Pure Dart: `ispectify`, `ispectify_db`, `ispectify_dio`, `ispectify_http`, `ispectify_ws`, `ispectify_bloc`, `ispectify_riverpod`
- Flutter: `ispect`, `ispect_layout`

Run the matching commands:

- Pure Dart:
  - `cd packages/$ARGUMENTS && dart pub get` (`dart pub get --no-example` for `ispectify_db`)
  - `cd packages/$ARGUMENTS && dart analyze --fatal-infos`
  - `cd packages/$ARGUMENTS && flutter test --dart-define=ISPECT_ENABLED=true --coverage` (add `--no-pub` for `ispectify_db`)
- Flutter:
  - `cd packages/$ARGUMENTS && flutter pub get`
  - `cd packages/$ARGUMENTS && flutter analyze --fatal-infos`
  - `cd packages/$ARGUMENTS && flutter test --dart-define=ISPECT_ENABLED=true --coverage`

Also run `test/production_safety_test.dart` without the define:

- Pure Dart: `cd packages/$ARGUMENTS && dart test --run-skipped test/production_safety_test.dart`
- Flutter: `cd packages/$ARGUMENTS && flutter test --run-skipped test/production_safety_test.dart`

If `$ARGUMENTS` is `web_logs_viewer`, run:

- `cd web_logs_viewer && flutter pub get`
- `cd web_logs_viewer && flutter analyze`
- `cd web_logs_viewer && flutter test`

Summarize pass/fail output and point to the first actionable failure.
