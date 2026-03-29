# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ISpect is a modular Flutter/Dart debugging and inspection toolkit — a monorepo with 7 pub packages plus a web log viewer app. It provides network, database, performance, widget tree, logging, and device inspection via an in-app panel.

## Monorepo Structure

```
packages/
  ispectify/          # Core logging engine (pure Dart, no Flutter)
  ispectify_dio/      # Dio HTTP interceptor
  ispectify_http/     # http package interceptor
  ispectify_ws/       # WebSocket traffic capture
  ispectify_db/       # Database operation tracking (pure Dart)
  ispectify_bloc/     # BLoC event/state observer
  ispect/             # Flutter UI: inspector panel, log viewer, widgets
web_logs_viewer/      # Standalone web app for log file viewing
bash/                 # Build & release automation scripts
docs/                 # VERSION_MANAGEMENT.md
```

**Dependency chain**: `ispectify` is the base → all `ispectify_*` packages depend on it → `ispect` depends on all of them.

## Version Management

**Single source of truth**: `version.config` (currently `4.8.0-dev05`).

**Never manually edit** package `pubspec.yaml` versions. Use:

```bash
./bash/update_versions.sh --bump patch|minor|major
./bash/update_versions.sh --dry-run  # preview
```

This propagates to all `pubspec.yaml` files, internal dependency constraints, and example apps.

**Validation**:

```bash
./bash/check_version_sync.sh
./bash/check_dependencies.sh
```

## Common Commands

### Testing

```bash
# Pure Dart packages
cd packages/ispectify && dart test
cd packages/ispectify_db && dart test

# Flutter packages
cd packages/ispect && flutter test
cd packages/ispectify_dio && flutter test
cd packages/ispectify_http && flutter test
cd packages/ispectify_ws && flutter test
cd packages/ispectify_bloc && flutter test
```

### Linting

```bash
# Dart packages
cd packages/ispectify && dart analyze --fatal-infos

# Flutter packages
cd packages/ispect && flutter analyze --fatal-infos
```

### CHANGELOG & README Sync

```bash
./bash/update_changelog.sh           # Sync root CHANGELOG to packages
./bash/sync_readme.sh                # Sync root README to packages
```

Root `CHANGELOG.md` and `README.md` are the sources of truth — edit those, then sync.

### Publishing

```bash
./bash/publish.sh --dry-run          # Validate
./bash/publish.sh --auto             # Publish (dependency-ordered)
```

Publish order: `ispectify` → `ispectify_db` → `ispectify_bloc` → `ispectify_dio` → `ispectify_http` → `ispectify_ws` → `ispect`.

## Architecture Patterns

- **Interceptor pattern** for network: settings class + interceptor class + redaction support + logger integration
- **Observer pattern** for state: `ISpectBlocObserver`, `ISpectNavigatorObserver`
- **Database tracing**: `logger.dbTrace<T>()` wrapper with sampling rate and slow query detection
- **Filter & redaction**: `ISpectFilter` interface, `RedactionService` for sensitive data masking
- `dependency_overrides` in pubspec files are **intentional** for monorepo local development — don't remove them

## Linter Rules (analysis_options.yaml)

Strict mode enabled (`strict-casts`, `strict-inference`, `strict-raw-types`). Key enforced rules:

- `avoid_print`, `avoid_dynamic_calls`
- `prefer_const_constructors`, `prefer_final_locals`
- `always_declare_return_types`, `prefer_typing_uninitialized_variables`
- `use_key_in_widget_constructors`

## Production Safety

ISpect is flag-gated and tree-shaken out of release builds:

```bash
flutter run --dart-define=ISPECT_ENABLED=true   # Development
flutter build apk                               # Production (flag omitted = zero footprint)
```

## Property Access Convention

Use direct Flutter API access, not wrappers:

```dart
// DO:
Theme.of(context).colorScheme.primary
Gap(8)

// DON'T:
getPrimary(colorScheme)
Constants.defaultPadding
```

## CI/CD

- `.github/workflows/test.yml` — runs analyze + test on all packages
- `.github/workflows/validate_versions.yml` — checks version sync on PRs
- `.github/workflows/sync_versions_and_changelogs.yml` — auto-syncs on version.config/CHANGELOG/README changes

## Reference Docs

- `bash/README.md` — automation scripts documentation
- `docs/VERSION_MANAGEMENT.md` — version system details
- `.github/copilot-instructions.md` — comprehensive AI agent guide
