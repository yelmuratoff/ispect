# Contributing to ISpect

Thanks for the interest. This is the short version of how the monorepo is laid out and what each PR needs.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.32.6+).
- [Dart SDK](https://dart.dev/get-dart) (stable).

## Monorepo structure

```
packages/
  ispectify/          # Core logging engine (pure Dart).
  ispectify_dio/      # Dio HTTP interceptor.
  ispectify_http/     # http package interceptor.
  ispectify_ws/       # WebSocket traffic capture.
  ispectify_db/       # Database operation tracing (pure Dart).
  ispectify_bloc/     # BLoC event and state observer.
  ispect/             # Flutter UI: inspector panel, log viewer, widgets.
```

Dependency chain: `ispectify` → `ispectify_*` → `ispect`.

## Local setup

```bash
git clone https://github.com/yelmuratoff/ispect.git
cd ispect

# Install the pre-commit hook.
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# Validate version and dependency consistency.
./bash/check_version_sync.sh && ./bash/check_dependencies.sh
```

## Running tests and lint

```bash
# Pure Dart packages.
cd packages/ispectify && dart test && dart analyze --fatal-infos

# Flutter packages.
cd packages/ispect && flutter test && flutter analyze --fatal-infos
```

## Version management

`version.config` is the single source of truth. Never edit package `pubspec.yaml` versions by hand.

```bash
# Bump version.
./bash/update_versions.sh --bump patch|minor|major

# Validate sync.
./bash/check_version_sync.sh
```

See [docs/VERSION_MANAGEMENT.md](docs/VERSION_MANAGEMENT.md) for the full reference.

## Automation scripts

Build and release scripts live in `bash/`. See [bash/README.md](bash/README.md) for the catalog.

## Pull request requirements

1. Tests pass: `dart test` or `flutter test` for affected packages.
2. Analyzer clean: `dart analyze --fatal-infos` or `flutter analyze --fatal-infos` with zero issues.
3. Versions in sync. Do not edit `pubspec.yaml` versions by hand.
4. Changelog entry in the root `CHANGELOG.md` for user-facing changes.
5. `dependency_overrides` in pubspec files are intentional for monorepo development. Leave them in.

## Code style

- Strict analyzer mode (`strict-casts`, `strict-inference`, `strict-raw-types`).
- Follow [Effective Dart](https://dart.dev/effective-dart) naming and structure.
- No `print` or `debugPrint`. Use `ISpect.logger` for package logging.
