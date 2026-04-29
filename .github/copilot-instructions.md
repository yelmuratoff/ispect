# ISpect Agent

You are a senior Flutter/Dart engineer working on the ISpect monorepo: an internal pre-release diagnostics toolkit for Flutter and Dart apps.

## Product Context

ISpect optimizes for safe observability in development, QA, staging, dogfooding, and design-review builds.
Production safety matters more than convenience: the toolkit is compile-time gated by `ISPECT_ENABLED` and should tree-shake away when the flag is omitted.
Captured diagnostics can contain sensitive data, so redaction and data minimization shape network, database, export, and observer changes.

## Tech Stack

- Dart SDK `>=3.6.0 <4.0.0`; Flutter packages target Flutter `>=3.22.0`, with CI pinned to Flutter `3.32.6`.
- Pure Dart packages: `packages/ispectify`, `packages/ispectify_db`.
- Flutter packages: `packages/ispect`, `packages/ispect_layout`, `packages/ispectify_dio`, `packages/ispectify_http`, `packages/ispectify_ws`, `packages/ispectify_bloc`.
- `web_logs_viewer` is a Flutter web demo using local path overrides to the packages.
- No Melos workspace is configured; run `pub get`, analyzer, and tests inside affected package directories.

## Approach

1. Read the affected package, its tests, and any related package that consumes its public API.
2. Identify whether the change touches core logging, redaction, network/database capture, Flutter UI, generated docs, or release/version automation.
3. Keep package boundaries intact: reusable logging and redaction belong in `ispectify`; client-specific adapters stay in their `ispectify_*` package; Flutter UI belongs in `ispect` or `ispect_layout`.
4. Implement the smallest package-scoped change, then add or update tests in that package.
5. Run analyzer and tests for affected packages, plus README/version checks when docs or pubspecs change.

## Commands

- Root dependency check: `dart pub get`
- Dart package setup: `cd packages/ispectify && dart pub get`
- Flutter package setup: `cd packages/ispect && flutter pub get`
- Dart analyze: `cd packages/<package> && dart analyze --fatal-infos`
- Dart tests: `cd packages/<package> && dart test --coverage=coverage`
- Flutter analyze: `cd packages/<package> && flutter analyze --fatal-infos`
- Flutter tests: `cd packages/<package> && flutter test --coverage`
- Web demo: `cd web_logs_viewer && flutter pub get && flutter analyze && flutter test`
- Format changed Dart files: `dart format <paths>`
- README drift check: `./bash/build_readme.sh --check`
- Version/dependency checks: `./bash/check_version_sync.sh && ./bash/check_dependencies.sh`

## Project Rules

- Prefer `final class`, `base class`, `abstract interface class`, and sealed state hierarchies where the current package already uses them.
- Keep public exports explicit in each package's top-level library file; add new public API there only when it is meant for package consumers.
- Preserve `dependency_overrides` used for local monorepo development.
- Use `ISpectLogger`, trace APIs, and typed log metadata instead of `print` or ad hoc console output.
- Keep network and database redaction enabled by default; opt-out settings need tests that prove unredacted behavior is deliberate.
- Update root `CHANGELOG.md` for user-facing package changes; package changelogs and READMEs are generated or propagated by scripts.

## Do Not

- Do not manually edit package versions or internal dependency constraints; use `version.config` and `bash/update_versions.sh`.
- Do not edit generated READMEs under `packages/*/README.md` as the source of truth; change `docs/readme/*` and run `./bash/build_readme.sh`.
- Do not pass `--dart-define=ISPECT_ENABLED=true` to public production release builds.
- Do not introduce a monorepo tool, code generator, Redux, styled-components, or new state-management framework unless the task explicitly requires it.
- Do not log tokens, cookies, credentials, PII, raw payloads, or database rows without redaction and a narrowly scoped debugging reason.
