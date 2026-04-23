# Tooling & Automation (bash/)

Maintenance scripts, quality gates, and release helpers for the ISpect monorepo.

## Contents

Scripts:

- `pre-commit.sh` — local git hook (version sync, dependency sync, README sync, changelog presence).
- `publish.sh` — ordered multi-package publish with preflight validation, dry-run, and auto mode.
- `update_versions.sh` — semantic bump and propagation of version + internal dependency constraints.
- `update_changelog.sh` — append / propagate a specific changelog section or overwrite all.
- `build_readme.sh` — assemble every package README from `docs/readme/` sources (primary doc builder).
- `update_readme.sh` — thin wrapper over `build_readme.sh` for symmetry with `update_versions.sh`.
- `check_version_sync.sh` — ensure every package version matches `version.config`.
- `check_dependencies.sh` — verify internal dependency constraints reference the current version.
- `bump_version.sh` — legacy bump helper (kept for backward compatibility; prefer `update_versions.sh --bump`).

## Quick start

```bash
# 1. Install pre-commit hook
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# 2. Validate everything before working
./bash/check_version_sync.sh && ./bash/check_dependencies.sh && ./bash/build_readme.sh --check
```

```bash
./bash/update_changelog.sh --full-copy && ./bash/update_versions.sh && ./bash/sync_readme.sh && dart format .
```

## Version management

Primary source of truth: `version.config` (line `VERSION=X.Y.Z`).

```bash
# Dry-run (see what would change)
./bash/update_versions.sh --dry-run

# Bump patch / minor / major
./bash/update_versions.sh --bump patch
./bash/update_versions.sh --bump minor
./bash/update_versions.sh --bump major
```

`update_versions.sh`:

- Updates each package `version:` line.
- Aligns internal dependency references (`^<VERSION>`).
- Updates example pubspec internal references.
- Ensures a root CHANGELOG section exists; then propagates its section to packages.
- Supports `--dry-run` for a non-destructive preview.

## Changelog propagation

```bash
# Append the latest root section to packages (default, safest).
./bash/update_changelog.sh

# Propagate a specific version section.
./bash/update_changelog.sh --version 5.0.0-dev15

# Overwrite every package CHANGELOG with root (destructive).
./bash/update_changelog.sh --full-copy --yes
```

## README management

Package READMEs are **generated** from focused, per-package sources in `docs/readme/`. Do not edit `packages/*/README.md` by hand — edits are overwritten on the next build.

Layout:

```
docs/readme/
  _partials/
    header.md              # logo + pub.dev badges (uses {{package}} placeholder)
    footer.md              # contributing, license, contrib-rocks
    install_matrix.md      # toolkit package table
    redaction.md           # shared redaction config block
    production_safety.md   # shared tree-shaking / ISPECT_ENABLED block
  root.md                  # body for the repo-root README.md
  ispect.md                # body for packages/ispect/README.md
  ispect_layout.md         # body for packages/ispect_layout/README.md
  ispectify.md             # body for packages/ispectify/README.md
  ispectify_dio.md         # body for packages/ispectify_dio/README.md
  ispectify_http.md        # body for packages/ispectify_http/README.md
  ispectify_ws.md          # body for packages/ispectify_ws/README.md
  ispectify_db.md          # body for packages/ispectify_db/README.md
  ispectify_bloc.md        # body for packages/ispectify_bloc/README.md
```

Markers expanded during build:

- `<!-- partial:NAME -->` → content of `docs/readme/_partials/NAME.md`.
- `{{version}}` → `VERSION` from `version.config`.
- `{{package}}` → target package name (root uses `ispect`).

Commands:

```bash
# Rebuild every README from sources.
./bash/build_readme.sh

# Verify outputs match sources (used by pre-commit and CI).
./bash/build_readme.sh --check

# Rebuild a single target.
./bash/build_readme.sh --package ispect_layout

# Preview without writing.
./bash/build_readme.sh --dry-run
```

Editing workflow: change the relevant `docs/readme/<package>.md` (or a partial), run `./bash/build_readme.sh`, review the generated file, commit both the source and the output.

## Publish workflow

```bash
# Ensure versions aligned and READMEs built.
./bash/update_versions.sh --dry-run
./bash/build_readme.sh

# Add / propagate changelog section for the current version.
./bash/update_changelog.sh --version $(grep VERSION version.config | cut -d= -f2)

# Dry-run publish (all packages in dependency order).
./bash/publish.sh --dry-run

# Real publish (no prompts).
./bash/publish.sh --auto
```

`publish.sh` features:

- Ordered dependency publishing.
- Preflight: forbids `any` constraints and committed `Podfile.lock`.
- Failure summarisation with per-package logs in `.publish_logs`.
- `--dry-run`, `--auto`, `-v/--verbose`.

## Pre-commit hook

Install:

```bash
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

Checks performed:

- Version synchronisation with `version.config`.
- Internal dependency versions (`^<VERSION>`).
- Generated READMEs match `docs/readme/` sources.
- Root changelog contains the current version.

## Daily macros

```bash
# Check everything is consistent.
./bash/check_version_sync.sh \
  && ./bash/check_dependencies.sh \
  && ./bash/build_readme.sh --check

# Sync everything after a version bump.
./bash/update_versions.sh --bump patch \
  && ./bash/update_changelog.sh --version $(grep VERSION version.config | cut -d= -f2) \
  && ./bash/build_readme.sh
```

## Notes

- Internal path overrides during local development may trigger pub.dev hints (acceptable for monorepo cycles).
- Always inspect dry-run output before a real publish.
- Use semantic bump flags for consistent version progression.

---

Keep automation simple, deterministic, auditable.
