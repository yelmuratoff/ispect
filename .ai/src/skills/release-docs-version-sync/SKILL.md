---
name: release-docs-version-sync
description: Use this skill when asked to update versions, prepare a release, sync changelogs, rebuild README files, fix README drift, validate package dependencies, or handle prerelease bumps in ISpect, including "release prep", "bump dev version", "sync docs", "README check failed", or "version mismatch".
---

# Release Docs Version Sync

Use the repository scripts for version, changelog, README, and publish-preflight workflows.

## Steps

1. Read `version.config` to identify the current `VERSION`.
2. For version changes, prefer a dry run first:
   - `./bash/update_versions.sh --dry-run`
3. For standard release preparation, run one of:
   - `./bash/release_prep.sh`
   - `./bash/release_prep.sh --skip-bump`
   - `./bash/release_prep.sh --carry-changelog`
4. For changelog-only propagation, update root `CHANGELOG.md`, then run:
   - `./bash/update_changelog.sh --version <VERSION>`
5. For README edits, change the source under `docs/readme/**`, then run:
   - `./bash/build_readme.sh`
6. Validate consistency:
   - `./bash/check_version_sync.sh`
   - `./bash/check_dependencies.sh`
   - `./bash/build_readme.sh --check`
7. Before publishing, run:
   - `./bash/publish.sh --dry-run`
8. Report generated files separately from source edits in the final summary.

## Gotchas

- `version.config` is the source of truth; do not hand-edit package `version:` fields or internal `^<VERSION>` constraints.
- Root and package README files are generated from `docs/readme/**`; direct README edits will be overwritten.
- `./bash/publish.sh --auto` performs a real publish and should only run after an explicit user request.
- `dependency_overrides` for local package paths are intentional in this monorepo.
