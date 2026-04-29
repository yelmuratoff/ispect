---
description: Prepare an ISpect release or prerelease using the repo scripts
argument-hint: "[--skip-bump|--carry-changelog|--dry-run]"
---

Use the repository release workflow, not manual pubspec edits.

1. Read `version.config`, root `CHANGELOG.md`, and `bash/README.md`.
2. If `$ARGUMENTS` contains `--dry-run`, run `./bash/update_versions.sh --dry-run` and `./bash/build_readme.sh --check`.
3. Otherwise run the appropriate prep command:
   - Standard release prep: `./bash/release_prep.sh`
   - Re-sync after editing changelog/docs: `./bash/release_prep.sh --skip-bump`
   - Dev prerelease carry-forward: `./bash/release_prep.sh --carry-changelog`
4. Run `./bash/check_version_sync.sh`, `./bash/check_dependencies.sh`, and `./bash/build_readme.sh --check`.
5. For publish validation only, run `./bash/publish.sh --dry-run`.

Do not run `./bash/publish.sh --auto` unless the user explicitly asks to publish.
