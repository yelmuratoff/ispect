# Quality Gates

Signals expected before a change is merged.

## Local checks

Run from the affected package directory:

```bash
dart analyze --fatal-infos
flutter test --dart-define=ISPECT_ENABLED=true --coverage
```

For Flutter packages:

```bash
flutter analyze --fatal-infos
flutter test --dart-define=ISPECT_ENABLED=true --coverage
```

Diagnostics are compiled out unless `ISPECT_ENABLED` is defined, so the suites
need the define to reach their assertions. Packages that ship
`test/production_safety_test.dart` assert the opposite and run without it:

```bash
# Pure Dart packages (ispectify*).
dart test --run-skipped test/production_safety_test.dart

# Flutter packages (ispect, ispect_layout), whose tests import flutter_test.
flutter test --run-skipped test/production_safety_test.dart
```

Generated README files must match `docs/readme/`:

```bash
dart run tool/bin/ispect_tool.dart readme --check
```

Package versions and internal dependencies must stay synchronized:

```bash
dart run tool/bin/ispect_tool.dart version check
dart run tool/bin/ispect_tool.dart deps
```

## CI signals

| Signal                                          | Required | Notes                                                                     |
| ----------------------------------------------- | -------- | ------------------------------------------------------------------------- |
| Dart package analyze and tests                  | Yes      | Covers `ispectify` and `ispectify_db`.                                    |
| Flutter package analyze and tests, pinned SDK   | Yes      | Compatibility baseline. Covers `ispect`, `ispect_layout`, and the other `ispectify_*` packages. |
| Flutter package analyze and tests, latest stable | Advisory | Tracks future breakage without blocking unrelated work.                   |
| README generation check                         | Yes      | Catches drift in generated READMEs.                                       |
| Version and dependency sync                     | Yes      | Keeps monorepo package versions aligned.                                  |
| Production-safety API matrix                    | Yes      | Calls every package's public diagnostics entry points with `ISPECT_ENABLED` omitted. |
| Production-safety AOT check                     | Yes      | Requires exact implementation sentinels to be absent when disabled and present in an enabled control build. |

## Coverage policy

Coverage is reported to Codecov per package flag. It does not gate merges: the project and patch statuses in `codecov.yml` are informational, and it defines no `ispectify_riverpod` flag yet.

Gates are planned to land package by package, starting with the business-critical core packages:

- `ispectify`
- `ispectify_dio`
- `ispectify_http`
- `ispectify_db`
- `ispectify_ws`
- `ispectify_bloc`
- `ispectify_riverpod`

A repository-wide threshold will not land until generated code, examples, and UI-heavy packages are either excluded or measured separately.
