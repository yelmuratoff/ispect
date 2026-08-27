---
description: Prepare an ISpect release or prerelease using the repo tooling
argument-hint: "[--skip-bump|--carry-changelog|--dry-run]"
---

Use the repository release workflow, not manual pubspec edits. Everything runs
through the Dart CLI in `tool/`; the scripts in `bash/` are frozen and must not
be called.

0. If `tool/.dart_tool` is absent, run `cd tool && dart pub get` first.
1. Read `version.config`, root `CHANGELOG.md`, and `tool/README.md`.
2. If `$ARGUMENTS` contains `--dry-run`, run:
   - `dart run tool/bin/ispect_tool.dart sync --dry-run`
   - `dart run tool/bin/ispect_tool.dart readme --check`
3. Otherwise run the appropriate prep command:
   - Standard release prep: `dart run tool/bin/ispect_tool.dart release-prep`
   - Re-sync after editing changelog/docs: `dart run tool/bin/ispect_tool.dart release-prep --skip-bump`
   - Dev prerelease carry-forward: `dart run tool/bin/ispect_tool.dart release-prep --carry-changelog`
4. Validate: `dart run tool/bin/ispect_tool.dart version check`, `deps`, `readme --check`, and `llms --check`.
5. Before publishing, run `dart run tool/bin/ispect_tool.dart check-published` — it refuses a version the resolver would not rank above what pub.dev already serves. Treat a block as a wrong version, never as a reason to pass `--skip-pub-version-check`.
6. For publish validation only, run `dart run tool/bin/ispect_tool.dart publish --dry-run`.

Do not run `dart run tool/bin/ispect_tool.dart publish --auto` unless the user explicitly asks to publish.
