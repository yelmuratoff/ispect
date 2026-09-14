---
description: Prepare an ISpect release or prerelease using the repo tooling
argument-hint: "[--skip-bump|--carry-changelog|--dry-run]"
---

Use the repository release workflow, not manual pubspec edits. Everything runs
through the Dart CLI in `tool/`; the release bash scripts are deleted, and `bash/`
keeps only the benchmark scripts used by `.github/workflows/benchmarks.yml`.

0. If `tool/.dart_tool` is absent, run `cd tool && dart pub get` first.
1. Read `version.config`, root `CHANGELOG.md`, and `tool/README.md`.
2. If `$ARGUMENTS` contains `--dry-run`, run:
   - `dart run tool/bin/ispect_tool.dart sync --dry-run`
   - `dart run tool/bin/ispect_tool.dart readme --check`
3. Otherwise run the appropriate prep command:
   - Standard release prep: `dart run tool/bin/ispect_tool.dart release-prep`
   - Re-sync after editing changelog/docs: `dart run tool/bin/ispect_tool.dart release-prep --skip-bump`
   - Dev prerelease carry-forward: `dart run tool/bin/ispect_tool.dart release-prep --carry-changelog`
   - Stable cut from a prerelease: `dart run tool/bin/ispect_tool.dart version bump <X.Y.Z>`, then follow `docs/VERSION_MANAGEMENT.md`. `release-prep` only bumps by `patch|minor|major` (from `7.0.0-rc.13`: `rc.14`, `7.1.0`, `8.0.0`), so never use those for it.
4. Validate everything at once: `dart run tool/bin/ispect_tool.dart check`.
5. Before publishing, run `dart run tool/bin/ispect_tool.dart check-published` - it refuses a version the resolver would not rank above what pub.dev already serves. Treat a block as a wrong version, never as a reason to pass `--skip-pub-version-check`.
6. For publish validation only, run `dart run tool/bin/ispect_tool.dart publish --dry-run`.

Do not run `dart run tool/bin/ispect_tool.dart publish --auto` unless the user explicitly asks to publish.
