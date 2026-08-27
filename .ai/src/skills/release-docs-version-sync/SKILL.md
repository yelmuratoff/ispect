---
name: release-docs-version-sync
description: Use this skill when asked to update versions, prepare a release, sync changelogs, rebuild README files, fix README drift, validate package dependencies, or handle prerelease bumps in ISpect, including "release prep", "bump dev version", "sync docs", "README check failed", or "version mismatch".
---

# Release Docs Version Sync

Use the repository scripts for version, changelog, README, and publish-preflight workflows.

## Steps

The tooling is a Dart CLI in `tool/`. Run `cd tool && dart pub get` once after a
fresh clone, then drive everything through `dart run tool/bin/ispect_tool.dart`.
The scripts in `bash/` are frozen and slated for deletion — do not call or edit
them.

1. Read `version.config` to identify the current `VERSION`.
2. For version changes, prefer a dry run first:
   - `dart run tool/bin/ispect_tool.dart sync --dry-run`
3. For standard release preparation, run one of:
   - `dart run tool/bin/ispect_tool.dart release-prep`
   - `dart run tool/bin/ispect_tool.dart release-prep --skip-bump`
   - `dart run tool/bin/ispect_tool.dart release-prep --carry-changelog`
4. For changelog-only propagation, update root `CHANGELOG.md`, then run:
   - `dart run tool/bin/ispect_tool.dart changelog --version <VERSION>`
5. For README edits, change the source under `docs/readme/**`, then run:
   - `dart run tool/bin/ispect_tool.dart readme`
6. Validate consistency:
   - `dart run tool/bin/ispect_tool.dart version check`
   - `dart run tool/bin/ispect_tool.dart deps`
   - `dart run tool/bin/ispect_tool.dart readme --check`
   - `dart run tool/bin/ispect_tool.dart llms --check`
7. Before publishing, run:
   - `dart run tool/bin/ispect_tool.dart publish --dry-run`
8. Report generated files separately from source edits in the final summary.

## Prerelease numbering

Separate the counter from its label with a dot — `7.1.0-dev.1`, `7.1.0-dev.2`, … `7.1.0-dev.10`. Semver compares a dot-separated numeric identifier as a number and an identifier containing letters as text, so the glued form `7.1.0-dev10` resolves *below* `7.1.0-dev8` and consumers keep getting the older code.

- The scripts refuse any bump that Pub does not order above the current `VERSION`, and warn while `VERSION` still uses the glued form.
- `ispect_tool check-published` asks pub.dev what it already serves and blocks a version the resolver does not rank above the peak of the same `MAJOR.MINOR` line. If it blocks, the version is wrong — do not reach for `--skip-pub-version-check`.
- A glued series already on pub.dev cannot be fixed by renumbering: the next release has to leave the label (`7.1.0-rc.1`) or the prerelease (`7.1.0`).
- `7.0.0-dev8` through `7.0.0-dev11` are published in the glued form, and Pub ranks `7.0.0-dev9` highest of them. Anything below `7.0.0-dev9` is invisible to consumers.

## Gotchas

- `version.config` is the source of truth; do not hand-edit package `version:` fields or internal `^<VERSION>` constraints.
- Root and package README files are generated from `docs/readme/**`; direct README edits will be overwritten.
- `ispect_tool publish --auto` performs a real publish and should only run after an explicit user request.
- `dependency_overrides` for local package paths are intentional in this monorepo.
