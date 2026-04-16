# Contributing to ISpect

Thanks for your interest in contributing! This guide covers the essentials for working with the ISpect monorepo.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.32.6+)
- [Dart SDK](https://dart.dev/get-dart) (stable)

## Monorepo Structure

```
packages/
  ispectify/          # Core logging engine (pure Dart)
  ispectify_dio/      # Dio HTTP interceptor
  ispectify_http/     # http package interceptor
  ispectify_ws/       # WebSocket traffic capture
  ispectify_db/       # Database operation tracking (pure Dart)
  ispectify_bloc/     # BLoC event/state observer
  ispect/             # Flutter UI: inspector panel, log viewer, widgets
```

**Dependency chain**: `ispectify` → `ispectify_*` → `ispect`.

## Local Setup

```bash
# Clone the repo
git clone https://github.com/yelmuratoff/ispect.git
cd ispect

# Install pre-commit hook
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# Validate everything
./bash/check_version_sync.sh && ./bash/check_dependencies.sh
```

## Running Tests & Lint

```bash
# Pure Dart packages
cd packages/ispectify && dart test && dart analyze --fatal-infos

# Flutter packages
cd packages/ispect && flutter test && flutter analyze --fatal-infos
```

## Version Management

**Single source of truth**: `version.config`. Never edit package `pubspec.yaml` versions manually.

```bash
# Bump version
./bash/update_versions.sh --bump patch|minor|major

# Validate sync
./bash/check_version_sync.sh
```

See [docs/VERSION_MANAGEMENT.md](docs/VERSION_MANAGEMENT.md) for details.

## Automation Scripts

All build and release scripts live in `bash/`. See [bash/README.md](bash/README.md) for the full reference.

## Pull Request Requirements

1. **Tests pass** — `dart test` / `flutter test` for affected packages
2. **Analyzer clean** — `dart analyze --fatal-infos` / `flutter analyze --fatal-infos` with zero issues
3. **Versions in sync** — don't manually edit `pubspec.yaml` versions
4. **Changelog** — add an entry to the root `CHANGELOG.md` for user-facing changes
5. **`dependency_overrides`** in pubspec files are intentional for monorepo development — don't remove them

## Code Style

- Strict analyzer mode (`strict-casts`, `strict-inference`, `strict-raw-types`)
- Follow [Effective Dart](https://dart.dev/effective-dart) naming and structure
- No `print` / `debugPrint` — use `ISpect.logger` only
