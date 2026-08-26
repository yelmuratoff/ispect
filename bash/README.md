# Tooling & Automation (bash/)

Maintenance scripts, quality gates, and release helpers for the ISpect monorepo.

## Contents

Scripts:

- `release_prep.sh` — the single entry point for synchronizing every release-managed artifact, with or without a version bump.
- `pre-commit.sh` — local git hook (version sync, dependency sync, README sync, changelog presence).
- `publish.sh` — ordered multi-package publish with preflight validation, dry-run, and auto mode.
- `update_versions.sh` — internal helper for version metadata, internal dependency constraints, and the web-viewer lockfile.
- `update_changelog.sh` — append / propagate a specific changelog section or overwrite all.
- `build_readme.sh` — assemble every package README from `docs/readme/` sources (primary doc builder).
- `update_readme.sh` — thin wrapper over `build_readme.sh` for symmetry with `update_versions.sh`.
- `build_llms.sh` — generate the repo-root `llms.txt` AI navigation index from repository metadata.
- `check_version_sync.sh` — ensure every package version matches `version.config`.
- `check_dependencies.sh` — verify internal dependency constraints reference the current version.
- `bump_version.sh` — legacy bump helper kept for backward compatibility; prefer `release_prep.sh`.
- `run_benchmarks.sh` — AOT pure-Dart hot-path suite; writes `build/benchmarks/ispectify.json` and the generated report.
- `measure_release_size.sh` — builds the `ispect` example with `ISPECT_ENABLED` omitted and enabled, saving APKs and `--analyze-size` reports to `build/benchmarks/release-size/`.

Libraries:

- `lib/semver.sh` — version parsing, comparison, and prerelease bumps, ordered exactly the way Pub resolves constraints. Sourced by `release_prep.sh`, `update_versions.sh`, `bump_version.sh`, and `publish.sh`.
- `lib/pub_api.sh` — reads the version history the package host already published. Sourced by `publish.sh`.

Tests:

- `tests/semver_test.sh`, `tests/pub_api_test.sh`, `tests/release_prep_test.sh`, and `tests/update_versions_test.sh` — regression tests for the release scripts, run by `validate_versions.yml`.

## Quick start

```bash
# 1. Install pre-commit hook
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# 2. Validate everything before working
./bash/check_version_sync.sh && ./bash/check_dependencies.sh && ./bash/build_readme.sh --check
```

```bash
# Synchronize all release-managed files without changing VERSION.
./bash/release_prep.sh --skip-bump
```

`release_prep.sh` is the user-facing release workflow:

```bash
# Patch bump (default), changelog section, and every generated artifact.
./bash/release_prep.sh

# Explicit patch, minor, or major bump.
./bash/release_prep.sh --bump minor

# Keep VERSION and synchronize every release-managed artifact.
./bash/release_prep.sh --skip-bump

# Advance a prerelease and carry its existing notes forward.
./bash/release_prep.sh --carry-changelog

# Resume an interrupted prerelease sync without another bump.
./bash/release_prep.sh --skip-bump --recover-changelog

# Open CHANGELOG.md during the workflow.
./bash/release_prep.sh --edit
```

Every mode synchronizes `version.config`, package metadata and internal
constraints, the web-viewer lockfile, root and package changelogs, generated
READMEs, and `llms.txt`, then validates the result. If any step fails, managed
files are restored to their exact pre-run state.

## Version management

Primary source of truth: `version.config` (line `VERSION=X.Y.Z`).

### Prerelease numbering

Separate the counter from its label with a dot: `7.1.0-dev.1`, `7.1.0-dev.2`,
… `7.1.0-dev.10`. Semantic Versioning compares a dot-separated numeric
identifier as a number, but an identifier containing letters as text — so the
glued form `7.1.0-dev10` resolves *below* `7.1.0-dev8`, and Pub hands consumers
the older code while the newer version sits on pub.dev unreachable.

The scripts refuse to write a version that Pub does not order above the current
one, and warn whenever `VERSION` still glues its counter to the label. A series
already published in the glued form cannot be repaired by renumbering it: leave
the label (`7.1.0-rc.1`) or the prerelease (`7.1.0`) instead.

`publish.sh` asks the host what it already serves and refuses to publish a
version the resolver does not rank above the peak of the same `MAJOR.MINOR`
line — the check that catches a version which uploads successfully and then
resolves to nobody. Releases on other lines are ignored, so backporting `6.1.8`
after `7.0.0` shipped still passes. `--skip-pub-version-check` opts out; an
unanswered request blocks rather than guesses.

```bash
# Preview the low-level version sync without writing.
./bash/update_versions.sh --dry-run

# Synchronize the complete release state without changing VERSION.
./bash/release_prep.sh --skip-bump
```

`update_versions.sh` is used by `release_prep.sh` and:

- Updates each package `version:` line.
- Aligns internal dependency references (`^<VERSION>`).
- Updates example pubspec internal references.
- Synchronizes local path-package versions in `web_logs_viewer/pubspec.lock`.
- Supports `--dry-run` for a non-destructive preview.

It does not update changelogs, READMEs, or `llms.txt`; use `release_prep.sh`
when the complete release state must be synchronized.

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

## llms.txt generation

The repo-root `llms.txt` is an AI navigation index (see [llmstxt.org](https://llmstxt.org)). It is **generated**, not hand-written — every entry is derived from repository metadata, so adding a package, interceptor, or doc and rerunning keeps it current with no manual edits:

- Title — fixed brand name; summary, repository, version — `packages/ispect/pubspec.yaml` + `version.config`.
- Package list — `name` / `description` from each `packages/*/pubspec.yaml`.
- Setup examples — each package's `example/` entrypoint.
- DB / WS adapters — `packages/ispectify_{db,ws}/example/lib/interceptors/*.dart`.
- Docs — H1 title of each `docs/*.md`.

```bash
# Regenerate llms.txt.
./bash/build_llms.sh

# Verify it is up to date (CI / pre-commit); exits 1 on drift.
./bash/build_llms.sh --check

# Preview without writing.
./bash/build_llms.sh --dry-run
```

Do not edit `llms.txt` by hand — edits are overwritten on the next build.

## Publish workflow

```bash
# Synchronize and validate every release-managed artifact.
./bash/release_prep.sh --skip-bump

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
  && ./bash/build_readme.sh --check \
  && ./bash/build_llms.sh --check

# Bump and synchronize everything.
./bash/release_prep.sh

# Synchronize everything without a bump.
./bash/release_prep.sh --skip-bump
```

## Notes

- Internal path overrides during local development may trigger pub.dev hints (acceptable for monorepo cycles).
- Always inspect dry-run output before a real publish.
- Use semantic bump flags for consistent version progression.

---

Keep automation simple, deterministic, auditable.
