# ISpect Workspace - AI Coding Agent Guide

## Project Overview

**ISpect** is a modular Flutter debugging and inspection toolkit distributed as a monorepo. The project provides network, database, performance, widget tree, logging, and device inspection tools via an in-app panel.

- **Architecture**: Monorepo with 7 independent pub packages (`ispect`, `ispectify`, `ispectify_dio`, `ispectify_http`, `ispectify_ws`, `ispectify_db`, `ispectify_bloc`)
- **Package Manager**: Single-source version management via `version.config`
- **Production Safety**: Flag-gated initialization (`--dart-define=ENABLE_ISPECT=true`) ensures zero footprint in release builds
- **Core Pattern**: Observer/interceptor pattern for passive instrumentation across HTTP, DB, WebSocket, and state management layers

## Critical Monorepo Concepts

### Version Synchronization (Single Source of Truth)

The entire workspace shares a **single version** defined in `version.config`:

```plaintext
VERSION=4.4.7
```

**Golden Rule**: Never manually edit package `pubspec.yaml` versions. Always use:

```bash
# Bump semantic version (patch/minor/major)
./bash/update_versions.sh --bump patch

# Dry-run to preview changes
./bash/update_versions.sh --dry-run
```

This script:
1. Updates `version.config`
2. Propagates version to all `packages/*/pubspec.yaml`
3. Synchronizes internal dependency constraints (e.g., `ispect` depends on `^4.4.7` of `ispectify`)
4. Updates example `pubspec.yaml` files
5. Propagates root `CHANGELOG.md` section to package changelogs

### Internal Dependency Management

Packages reference each other using **caret constraints** matching the current version:

```yaml
# packages/ispect/pubspec.yaml
dependencies:
  ispectify: ^4.4.7  # Always matches version.config

dependency_overrides:
  ispectify:
    path: ../ispectify  # Local dev override
```

The `dependency_overrides` section is **intentional** for monorepo development. Don't remove it.

**Validation Commands**:
```bash
./bash/check_version_sync.sh      # Verify all versions match
./bash/check_dependencies.sh      # Verify internal dep constraints
```

## Essential Developer Workflows

### Running Tests

**Never use raw `dart test` commands**. Use workspace tasks or package-specific commands:

```bash
# Via VS Code tasks (preferred)
# Run > Run Task > Select appropriate test task

# Manual invocation
cd packages/ispectify && dart test
cd packages/ispectify_http && dart test
```

**Common test pattern** (seen in `curl_utils_test.dart`, `logger_settings_test.dart`):
```dart
void main() {
  group('FeatureName', () {
    test('description of behavior', () {
      // Arrange, Act, Assert
    });
  });
}
```

### Building & Publishing

**Pre-publish checklist**:
```bash
# 1. Bump version and propagate changes
./bash/update_versions.sh --bump patch

# 2. Update CHANGELOG.md (root) with new section
# 3. Regenerate READMEs if configs changed
./bash/update_readme.sh generate all

# 4. Dry-run publish to validate
./bash/publish.sh --dry-run

# 5. Real publish (dependency-ordered, logs in .publish_logs/)
./bash/publish.sh --auto
```

The `publish.sh` script enforces:
- Dependency-ordered publishing (e.g., `ispectify` before `ispect`)
- No `any` version constraints
- No committed `Podfile.lock` files

### README Generation

READMEs are **generated** from templates, not manually edited:

```bash
# List available packages
./bash/update_readme.sh list

# Generate for one package (also updates root README for 'ispect')
./bash/update_readme.sh generate ispect

# Regenerate all
./bash/update_readme.sh generate all

# Dry-run validation
./bash/update_readme.sh dry-run
```

**Template structure**:
- Template: `readme_generator/template.md`
- Configs: `readme_generator/configs/<package>.json`
- Generator: `readme_generator/generate_readme.dart`

Version placeholders like `ispect: ^X.Y.Z` are auto-replaced with current `version.config` value.

### CHANGELOG Management

Root `CHANGELOG.md` is the source of truth. Propagate changes to packages:

```bash
# Append latest root section to package changelogs (safe, default)
./bash/update_changelog.sh

# Propagate specific version
./bash/update_changelog.sh --version 4.4.7

# Overwrite all package changelogs (destructive)
./bash/update_changelog.sh --full-copy --yes
```

## Package-Specific Patterns

### Interceptor Architecture (Dio/HTTP/WebSocket)

All network interceptors follow a consistent pattern:

1. **Settings class**: Configures what to log
2. **Interceptor class**: Implements framework-specific interface
3. **Redaction support**: Masks sensitive data via `RedactionService`
4. **Logger integration**: Calls `logger.logData()` with typed log models

**Example** (`ispectify_dio/lib/src/interceptor.dart`):
```dart
class ISpectDioInterceptor extends Interceptor {
  ISpectDioInterceptor({
    ISpectLogger? logger,
    this.settings = const ISpectDioInterceptorSettings(),
    RedactionService? redactor,
  }) {
    _logger = logger ?? ISpectLogger();
    _redactor = redactor ?? RedactionService();
  }

  // Override onRequest, onResponse, onError
  // Call _logger.logData() with DioRequestLog/DioResponseLog
}
```

**Redaction pattern**:
```dart
final redactedHeaders = _redactHeaders(options.headers, useRedaction);
final redactedBody = _redactBody(options.data, useRedaction);
```

### Observer Pattern (BLoC/Navigation)

State management and routing use observer pattern:

```dart
// BLoC observer
class ISpectBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    logger.logData(BlocEventLog(...));
  }
}

// Navigation observer
class ISpectNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    logger.logData(RouteLog(...));
  }
}
```

### Database Tracing Pattern (`ispectify_db`)

DB operations are wrapped in `logger.dbTrace()`:

```dart
final rows = await ISpect.logger.dbTrace<List<Map<String, Object?>>>(
  source: 'sqflite',
  operation: 'query',
  statement: 'SELECT * FROM users WHERE id = ?',
  args: [userId],
  table: 'users',
  run: () => db.rawQuery('SELECT * FROM users WHERE id = ?', [userId]),
  projectResult: (rows) => {'rows': rows.length},
);
```

Configuration is global:
```dart
ISpectDbCore.config = const ISpectDbConfig(
  sampleRate: 1.0,
  redact: true,
  slowQueryThreshold: Duration(milliseconds: 400),
);
```

## Code Quality Standards (From User Instructions)

### Flutter/Dart Best Practices

1. **SOLID Principles**: Apply DRY, KISS, YAGNI, composition-first design
2. **Widget Decomposition**: Extract large widgets into focused components
3. **const Constructors**: Use wherever possible for performance
4. **Resource Disposal**: Always dispose `TextEditingController`, `FocusNode`, `AnimationController`
5. **Context Safety**: Check `context.mounted` before `setState` in async operations
6. **State Management**: Use `FutureBuilder`/`StreamBuilder`/`ValueListenableBuilder` appropriately

### Property Access (Specific to This Project)

**DO**:
```dart
Theme.of(context).colorScheme.primary
Gap(8)
EdgeInsets.only(left: 16)
```

**DON'T**:
```dart
getPrimary(colorScheme)  // Wrapper functions
Constants.defaultPadding  // Extracted primitives (unless requested)
```

### Required Linter Compliance

From `analysis_options.yaml`:
```yaml
linter:
  rules:
    - avoid_print
    - prefer_const_constructors
    - use_key_in_widget_constructors
    - prefer_final_locals
    - always_declare_return_types
    - prefer_typing_uninitialized_variables
    - avoid_dynamic_calls
```

### Complete File Delivery

**Always deliver complete Dart files**, not snippets. Never use placeholders like `...existing code...`.

## Production Safety Pattern

All ISpect initialization is gated behind a flag:

```dart
const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  if (kEnableISpect) {
    final logger = ISpectFlutter.init();
    ISpect.run(() => runApp(MyApp()), logger: logger);
  } else {
    runApp(const MyApp());
  }
}
```

**Build commands**:
```bash
# Development
flutter run --dart-define=ENABLE_ISPECT=true

# Production (flag omitted = tree-shaken)
flutter build apk
```

## CI/CD Automation

### GitHub Actions Workflows

1. **Version Validation** (`.github/workflows/validate_versions.yml`)
   - Runs on PRs to `main`/`master`/`develop`
   - Validates version sync across packages
   - Checks internal dependency constraints
   - Ensures CHANGELOG documents current version

2. **Sync Versions and Changelogs** (`.github/workflows/sync_versions_and_changelogs.yml`)
   - Triggers on changes to `version.config` or `CHANGELOG.md`
   - Runs `update_versions.sh` and commits changes
   - Auto-commits updated `pubspec.yaml` files

### Pre-Commit Hook

Install for local validation:
```bash
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

Validates before commit:
- Version synchronization
- Internal dependency versions
- CHANGELOG formatting

## Key Files to Reference

| File/Directory | Purpose |
|---|---|
| `version.config` | Single source of truth for version |
| `bash/update_versions.sh` | Semantic version bumping + propagation |
| `bash/publish.sh` | Dependency-ordered multi-package publishing |
| `readme_generator/` | Template-based README generation |
| `packages/ispect/lib/ispect.dart` | Main export barrel file |
| `packages/ispectify/lib/src/ispectify.dart` | Core logging engine |
| `packages/ispectify_*/lib/src/interceptor.dart` | Interceptor implementations |

## Common Pitfalls

1. **Don't manually edit package versions** → Use `./bash/update_versions.sh`
2. **Don't edit generated READMEs** → Edit configs in `readme_generator/configs/` then regenerate
3. **Don't remove `dependency_overrides`** → Required for local monorepo development
4. **Don't use raw `dart test`** → Use workspace tasks or navigate to package directory
5. **Don't commit ISpect-enabled builds** → Always gate behind `--dart-define=ENABLE_ISPECT`
6. **Don't use placeholders in edits** → Deliver complete, runnable files

## Quick Reference Commands

```bash
# Version bump workflow
./bash/update_versions.sh --bump patch && \
./bash/update_changelog.sh && \
./bash/update_readme.sh generate all

# Validation workflow
./bash/check_version_sync.sh && \
./bash/check_dependencies.sh && \
./bash/update_readme.sh dry-run

# Publish workflow
./bash/publish.sh --dry-run && \
./bash/publish.sh --auto
```

---

**When in doubt**: Check `bash/README.md` or `docs/VERSION_MANAGEMENT.md` for detailed automation docs.
