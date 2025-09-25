# Tooling & Automation (bash/)

Maintenance scripts, quality gates, and release helpers for the ISpect monorepo.

## Contents

Scripts:
- pre-commit.sh – Local git hook (version sync, internal deps, changelog presence).
- publish.sh – Ordered multi‑package publish with preflight validation, dry‑run & auto mode.
- update_versions.sh – Semantic bump & propagation of version + internal dependency constraints.
- update_changelog.sh – Append / propagate a specific changelog section or overwrite all.
- update_readme.sh – Generate README files from template/configs (validate / dry‑run).
- check_version_sync.sh – Ensure every package version == version.config.
- check_dependencies.sh – Verify internal dependency constraints reference the current version.
- bump_version.sh – Legacy bump helper (kept for backward compatibility; prefer update_versions.sh --bump).

```bash
./bash/update_changelog.sh --full-copy && ./bash/update_versions.sh && ./bash/update_readme.sh generate all
```

## Quick Start

```bash
# 1. Install pre-commit hook
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# 2. Validate everything before working
./bash/check_version_sync.sh && ./bash/check_dependencies.sh

# 3. Generate all READMEs (after editing configs)
./bash/update_readme.sh generate all
```

## Version Management

Primary source of truth: `version.config` (line `VERSION=X.Y.Z`).

Semantic bump + propagate (recommended):
```bash
# Dry-run (see what would change)
./bash/update_versions.sh --dry-run

# Bump patch (e.g. 4.3.6 -> 4.3.7) and update all pubspecs & examples
./bash/update_versions.sh --bump patch

# Bump minor
./bash/update_versions.sh --bump minor

# Bump major
./bash/update_versions.sh --bump major
```

The script:
- Updates each package `version:` line.
- Aligns internal dependency references (`^<VERSION>`).
- Updates example pubspec internal references.
- Ensures a root CHANGELOG section exists; then propagates its section to packages.
- Supports `--dry-run` for a non‑destructive preview.

Legacy (still works):
```bash
./bash/bump_version.sh patch
```

## Changelog Propagation

`update_changelog.sh` modes:
```bash
# Append latest root section to packages (default safest mode)
./bash/update_changelog.sh

# Propagate a specific version section
./bash/update_changelog.sh --version 4.3.6

# Overwrite EVERY package CHANGELOG with root (destructive)
./bash/update_changelog.sh --full-copy --yes
```

## README Generation

`update_readme.sh` wraps the Dart generator.
```bash
# List packages (by config JSON)
./bash/update_readme.sh list

# Validate one config
./bash/update_readme.sh validate ispect

# Validate all (no files written)
./bash/update_readme.sh dry-run

# Generate for one
./bash/update_readme.sh generate ispectify_http

# Generate for all
./bash/update_readme.sh generate all
```

## Publish Workflow

Best‑practice multi‑package release (dry‑run first):
```bash
# Ensure working tree clean & versions aligned
./bash/update_versions.sh --dry-run

# Regenerate docs (if needed)
./bash/update_readme.sh generate all

# Changelog section already added? (root) – if not, add and propagate
./bash/update_changelog.sh --version $(grep VERSION version.config | cut -d= -f2)

# Dry-run publish (all packages in dependency order)
./bash/publish.sh --dry-run

# Real publish (no prompts)
./bash/publish.sh --auto
```

Features in `publish.sh`:
- Ordered dependency publishing.
- Preflight: forbids `any` constraints & committed Podfile.lock.
- Failure summarization with per‑package logs in `.publish_logs`.
- `--dry-run`, `--auto`, `-v/--verbose`.

## Pre-Commit Hook

Install:
```bash
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

Checks performed:
- Version synchronization with `version.config`.
- Internal dependency versions (`^<VERSION>`).
- Root changelog contains current version.
- (Optional) Additional custom project rules.

## Recommended Daily Macro

```bash
./bash/update_versions.sh --dry-run \
	&& ./bash/update_readme.sh dry-run \
	&& ./bash/update_readme.sh generate all \
	&& ./bash/update_changelog.sh --version $(grep VERSION version.config | cut -d= -f2)
```

## Minimal Release Shortcut

```bash
./bash/update_versions.sh --bump patch \
	&& ./bash/update_readme.sh generate all \
	&& ./bash/publish.sh --dry-run \
	&& ./bash/publish.sh --auto
```

## Notes
- Internal path overrides during local development may trigger pub.dev hints (acceptable for monorepo cycles).
- Always inspect dry-run output before real publish.
- Use semantic bump flags for consistent version progression.

## Old Personal Shortcut (Updated)
```bash
./bash/update_versions.sh --bump patch \
	&& ./bash/update_changelog.sh --version $(grep VERSION version.config | cut -d= -f2) \
	&& ./bash/update_readme.sh generate all
```

---
Keep automation simple, deterministic, auditable.