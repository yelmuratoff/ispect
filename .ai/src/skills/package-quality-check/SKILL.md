---
name: package-quality-check
description: Use this skill when asked to test, verify, validate, run checks, fix analyzer failures, or confirm CI readiness for an ISpect package, including vague requests like "check this package", "проверь тесты", "why CI fails", or "make it green". It chooses the correct Dart vs Flutter commands and adds README/version checks only when relevant.
---

# Package Quality Check

Run the correct package-scoped analyzer, tests, and repo consistency checks for ISpect.

## Steps

1. Identify the affected target from changed files or the user's package name.
2. Use pure Dart commands for `packages/ispectify` and `packages/ispectify_db`:
   - `cd packages/<package> && dart pub get`
   - `cd packages/<package> && dart analyze --fatal-infos`
   - `cd packages/<package> && dart test --coverage=coverage`
3. Use Flutter commands for `packages/ispect`, `packages/ispect_layout`, `packages/ispectify_dio`, `packages/ispectify_http`, `packages/ispectify_ws`, and `packages/ispectify_bloc`:
   - `cd packages/<package> && flutter pub get`
   - `cd packages/<package> && flutter analyze --fatal-infos`
   - `cd packages/<package> && flutter test --coverage`
4. Use Flutter web demo commands for `web_logs_viewer`:
   - `cd web_logs_viewer && flutter pub get`
   - `cd web_logs_viewer && flutter analyze`
   - `cd web_logs_viewer && flutter test`
5. If docs, changelogs, `version.config`, or package pubspecs changed, also run:
   - `./bash/check_version_sync.sh`
   - `./bash/check_dependencies.sh`
   - `./bash/build_readme.sh --check`
6. If failures occur, fix the first root-cause failure before rerunning the smallest relevant command.
7. Summarize the exact commands run and any remaining failures.

## Gotchas

- The repo root is not a Melos workspace; root-level `dart test` does not validate all packages.
- `ispectify_dio`, `ispectify_http`, `ispectify_ws`, and `ispectify_bloc` are Flutter-package CI jobs even though their code is mostly non-UI.
- Coverage directories are generated output; do not commit them.
- The pinned required Flutter CI signal is `3.32.6`; latest stable is advisory.
