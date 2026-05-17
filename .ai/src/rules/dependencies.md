# Dependency Rules

## Package Management

- Run `dart pub get` or `flutter pub get` inside the package being changed.
- Keep local `dependency_overrides` between monorepo packages; they are intentional for development.
- Keep internal package dependency constraints aligned with `version.config` through `./bash/update_versions.sh`.
- Use `./bash/check_dependencies.sh` after dependency or version changes.

## Adding Dependencies

- Prefer existing dependencies: `collection`, `meta`, `ansicolor`, `web`, `dio`, `http`, `http_interceptor`, `ws`, BLoC, and Flutter SDK libraries where already present.
- Add a new dependency only to the package that uses it, not to the root workspace.
- For publishable packages, avoid `any` constraints; `publish.sh` treats them as a preflight issue.

## Versioning

- `version.config` is the version source of truth.
- Do not manually edit package `version:` lines or internal `^<version>` constraints.
- Use `./bash/update_versions.sh --dry-run` before broad version sync changes.

## Anti-Patterns

- Do not introduce Melos or another workspace manager for one task.
- Do not remove path overrides from examples or `web_logs_viewer` while working locally.
- Do not commit generated `pubspec.lock` files for publishable packages unless the repo already tracks one there.
