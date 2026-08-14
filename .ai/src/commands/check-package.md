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
  - `cd packages/$ARGUMENTS && dart pub get`
  - `cd packages/$ARGUMENTS && dart analyze --fatal-infos`
  - `cd packages/$ARGUMENTS && flutter test --dart-define=ISPECT_ENABLED=true --coverage`
- Flutter:
  - `cd packages/$ARGUMENTS && flutter pub get`
  - `cd packages/$ARGUMENTS && flutter analyze --fatal-infos`
  - `cd packages/$ARGUMENTS && flutter test --dart-define=ISPECT_ENABLED=true --coverage`

Where `test/production_safety_test.dart` exists, also run it without the define:

- `cd packages/$ARGUMENTS && dart test --run-skipped test/production_safety_test.dart`

If `$ARGUMENTS` is `web_logs_viewer`, run:

- `cd web_logs_viewer && flutter pub get`
- `cd web_logs_viewer && flutter analyze`
- `cd web_logs_viewer && flutter test`

Summarize pass/fail output and point to the first actionable failure.
