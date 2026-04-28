# Quality Gates

This document describes the quality signals expected before changes are merged.

## Required Local Checks

Run checks from the affected package directory:

```bash
dart analyze --fatal-infos
dart test
```

For Flutter packages:

```bash
flutter analyze --fatal-infos
flutter test --coverage
```

Generated README files must match `docs/readme/`:

```bash
./bash/build_readme.sh --check
```

Package versions and internal dependencies must remain synchronized:

```bash
./bash/check_version_sync.sh
./bash/check_dependencies.sh
```

## CI Signals

| Signal                                          | Required | Notes                                                                     |
| ----------------------------------------------- | -------- | ------------------------------------------------------------------------- |
| Dart package analyze/tests                      | Yes      | Runs for pure Dart packages                                               |
| Flutter package analyze/tests on pinned Flutter | Yes      | Compatibility baseline                                                    |
| Flutter package analyze/tests on latest stable  | Advisory | Tracks future breakage without blocking unrelated work                    |
| README generation check                         | Yes      | Prevents generated README drift                                           |
| Version/dependency sync                         | Yes      | Keeps monorepo package versions aligned                                   |
| Production-safety APK check                     | Yes      | Builds a release APK without `ISPECT_ENABLED` and checks residual strings |

## Coverage Policy

Coverage is reported to Codecov. Before the stable `5.0.0` release, coverage gates should be introduced package by package, starting with business-critical core packages:

- `ispectify`
- `ispectify_dio`
- `ispectify_http`
- `ispectify_db`
- `ispectify_ws`
- `ispectify_bloc`

Do not add a repository-wide threshold until generated code, examples, and UI-heavy packages are excluded or measured separately.
