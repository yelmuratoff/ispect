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
dart test --run-skipped test/production_safety_test.dart
```

Generated README files must match `docs/readme/`:

```bash
./bash/build_readme.sh --check
```

Package versions and internal dependencies must stay synchronized:

```bash
./bash/check_version_sync.sh
./bash/check_dependencies.sh
```

## CI signals

| Signal                                          | Required | Notes                                                                     |
| ----------------------------------------------- | -------- | ------------------------------------------------------------------------- |
| Dart package analyze and tests                  | Yes      | Runs for pure Dart packages.                                              |
| Flutter package analyze and tests, pinned SDK   | Yes      | Compatibility baseline.                                                   |
| Flutter package analyze and tests, latest stable | Advisory | Tracks future breakage without blocking unrelated work.                   |
| README generation check                         | Yes      | Catches drift in generated READMEs.                                       |
| Version and dependency sync                     | Yes      | Keeps monorepo package versions aligned.                                  |
| Production-safety API matrix                    | Yes      | Calls every package's public diagnostics entry points with `ISPECT_ENABLED` omitted. |
| Production-safety AOT check                     | Yes      | Requires exact implementation sentinels to be absent when disabled and present in an enabled control build. |

## Coverage policy

Coverage is reported to Codecov. Coverage gates land package by package, starting with the business-critical core packages:

- `ispectify`
- `ispectify_dio`
- `ispectify_http`
- `ispectify_db`
- `ispectify_ws`
- `ispectify_bloc`
- `ispectify_riverpod`

A repository-wide threshold will not land until generated code, examples, and UI-heavy packages are either excluded or measured separately.
