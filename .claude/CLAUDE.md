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

**Dependency chain**: `ispectify` → `ispectify_*` packages → `ispect`.

## Where to Find Things

| What                                 | Where                                                    |
| ------------------------------------ | -------------------------------------------------------- |
| All log types (`ISpectLogType` enum) | `packages/ispectify/lib/src/models/log_type.dart`        |
| Log severity levels (`LogLevel`)     | `packages/ispectify/lib/src/models/log_level.dart`       |
| Trace categories                     | `packages/ispectify/lib/src/trace/trace_categories.dart` |
| Core logger (`ISpectLogger`)         | `packages/ispectify/lib/src/ispectify.dart`              |
| Domain trace extensions              | `packages/ispectify/lib/src/trace/extensions/`           |
| `ISpect` Flutter singleton           | `packages/ispect/lib/src/ispect.dart`                    |
| UI screens & widgets                 | `packages/ispect/lib/src/features/ispect/presentation/`  |
| ISpectTheme, ISpectOptions           | `packages/ispect/lib/src/core/res/`                      |
| Full working example (all features)  | `packages/ispect/example/lib/main.dart`                  |

## Architecture Patterns

- **Interceptor pattern** for network: settings class + interceptor class + redaction + logger integration
- **Trace extensions**: domain logging via `traceAsync`/`traceSync`/`traceStream` in `trace/trace_extension.dart`
- **Observer pattern** for state: `ISpectBlocObserver`, `ISpectNavigatorObserver`
- `dependency_overrides` in pubspec files are **intentional** for monorepo — don't remove them

## Version Management

**Single source of truth**: `version.config` (currently `5.0.0-dev04`).

**Never manually edit** package `pubspec.yaml` versions. Use:

```bash
./bash/update_versions.sh --bump patch|minor|major
./bash/check_version_sync.sh   # validate
```

## Common Commands

```bash
# Test
cd packages/ispectify && dart test
cd packages/ispect && flutter test

# Lint
cd packages/ispectify && dart analyze --fatal-infos
cd packages/ispect && flutter analyze --fatal-infos

# Sync docs
./bash/update_changelog.sh && ./bash/build_readme.sh

# Publish (dependency-ordered)
./bash/publish.sh --dry-run
./bash/publish.sh --auto
```

## Production Safety

ISpect is flag-gated — zero footprint in release builds when `--dart-define=ISPECT_ENABLED=true` is omitted. The `kISpectEnabled` constant controls this.

## Linter Rules

Strict mode (`strict-casts`, `strict-inference`, `strict-raw-types`). Key: `avoid_print`, `prefer_const_constructors`, `always_declare_return_types`, `use_key_in_widget_constructors`.

## CI/CD

- `test.yml` — analyze + test on all packages
- `validate_versions.yml` — version sync check on PRs
- `sync_versions_and_changelogs.yml` — auto-syncs on version.config/CHANGELOG/README changes

## Reference Docs

- `bash/README.md` — automation scripts
- `docs/VERSION_MANAGEMENT.md` — version system details
- `.github/copilot-instructions.md` — comprehensive AI agent guide
