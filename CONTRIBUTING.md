# Contributing to ISpect

Thanks for the interest. This is the short version of how the monorepo is laid out and what each PR needs.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.32.6+).
- [Dart SDK](https://dart.dev/get-dart) (stable).

## Monorepo structure

```
packages/
  ispectify/          # Core logging engine.
  ispectify_dio/      # Dio HTTP interceptor.
  ispectify_http/     # http package interceptor.
  ispectify_ws/       # WebSocket traffic capture.
  ispectify_db/       # Database operation tracing.
  ispectify_bloc/     # BLoC event and state observer.
  ispectify_riverpod/ # Riverpod provider lifecycle observer.
  ispect/             # Flutter UI: inspector panel, log viewer, widgets.
  ispect_layout/      # Visual layout inspector and color picker.
```

Only `ispect` and `ispect_layout` depend on Flutter. Every `ispectify*` package is pure Dart.

Dependency chain: `ispectify` → `ispectify_*` → `ispect`.

## Local setup

```bash
git clone https://github.com/yelmuratoff/ispect.git
cd ispect

# Install the pre-commit hook.
cp tool/hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# Validate version and dependency consistency.
dart run tool/bin/ispect_tool.dart check
```

## Running tests and lint

Diagnostics are compiled out unless `ISPECT_ENABLED` is defined, so every suite
needs the define to reach its assertions — including the pure Dart packages:

```bash
# Pure Dart packages.
cd packages/ispectify && flutter test --dart-define=ISPECT_ENABLED=true && dart analyze --fatal-infos

# Flutter packages.
cd packages/ispect && flutter test --dart-define=ISPECT_ENABLED=true && flutter analyze --fatal-infos
```

Packages that ship `test/production_safety_test.dart` assert the opposite and
run without the define:

```bash
cd packages/ispectify && dart test --run-skipped test/production_safety_test.dart
```

## Version management

`version.config` is the single source of truth. Never edit package `pubspec.yaml` versions by hand.

```bash
# Bump version.
dart run tool/bin/ispect_tool.dart sync --bump patch|minor|major

# Validate sync.
dart run tool/bin/ispect_tool.dart version check
```

See [docs/VERSION_MANAGEMENT.md](docs/VERSION_MANAGEMENT.md) for the full reference.

## Automation scripts

Build and release tooling is the Dart CLI in `tool/`. See [tool/README.md](tool/README.md) for the command table; run `cd tool && dart pub get` once after a fresh clone. `bash/` keeps only the two benchmark scripts, which stay shell because they are fixed command sequences.

## Pull request requirements

1. Tests pass: `flutter test --dart-define=ISPECT_ENABLED=true` for affected packages, plus the disabled-build check where `test/production_safety_test.dart` exists.
2. Analyzer clean: `dart analyze --fatal-infos` or `flutter analyze --fatal-infos` with zero issues.
3. Versions in sync. Do not edit `pubspec.yaml` versions by hand.
4. Changelog entry in the root `CHANGELOG.md` for user-facing changes.
5. `dependency_overrides` in pubspec files are intentional for monorepo development. Leave them in.

## Code style

- Strict analyzer mode (`strict-casts`, `strict-inference`, `strict-raw-types`).
- Follow [Effective Dart](https://dart.dev/effective-dart) naming and structure.
- No `print` or `debugPrint`. Use `ISpect.logger` for package logging.
