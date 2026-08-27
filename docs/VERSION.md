# ISpect Version Management

A short overview of the version-management workflow. The full reference lives in [`VERSION_MANAGEMENT.md`](./VERSION_MANAGEMENT.md).

## Tools and files

### Key files

- `version.config`, the single source of truth for the current version.
- `CHANGELOG.md`, the release notes for every version.
- `tool/`, the Dart CLI owning every release command. `release-prep` is the single command for bumps and release synchronization; `version check` and `deps` validate versions and internal dependencies. See `tool/README.md`.
- `bash/*.sh`, the previous implementation. Frozen and slated for deletion; the differential tests in `tool/test/` still run them to prove the two agree.

### GitHub Actions workflows

- `sync_versions_and_changelogs.yml`, syncs versions, dependencies, changelogs, and generated README files when sources change.
- `validate_versions.yml`, validates versions, dependencies, changelog entries, and generated README files in pull requests.
- `production_safety.yml`, runs the disabled API matrix and compares exact
  implementation sentinels in disabled and enabled release AOT builds.
- `test.yml`, runs analyze, tests, and coverage across packages.

## Version bump types

```bash
# Patch bump (default).
dart run tool/bin/ispect_tool.dart release-prep

# Explicit patch, minor, or major bump.
dart run tool/bin/ispect_tool.dart release-prep --bump major

# Keep VERSION and refresh all release-managed files.
dart run tool/bin/ispect_tool.dart release-prep --skip-bump

# Advance a prerelease and keep its current changelog notes.
dart run tool/bin/ispect_tool.dart release-prep --carry-changelog

# Resume an interrupted prerelease sync without another bump.
dart run tool/bin/ispect_tool.dart release-prep --skip-bump --recover-changelog
```

## Prerelease numbering

Write the counter as its own dot-separated identifier — `7.1.0-dev.1`,
`7.1.0-dev.2`, … `7.1.0-dev.10`. Glued to its label, the counter is compared as
text, so `7.1.0-dev10` resolves below `7.1.0-dev8` and consumers keep getting
the older code with no error anywhere. The scripts reject any version Pub does
not order above the current one, and `publish.sh` blocks a release that is not
ranked above the published peak of its `MAJOR.MINOR` line. Details and the
escape routes for an already published glued series live in
[VERSION_MANAGEMENT.md](VERSION_MANAGEMENT.md).

## CI process

When you update `CHANGELOG.md` or `version.config`, GitHub Actions automatically:

- Runs `release_prep.sh --skip-bump` to synchronize versions, dependencies, changelogs, generated READMEs, and `llms.txt`.
- Synchronizes the standalone web-viewer manifest and lockfile.
- Validates the lockfile with the CI-pinned Flutter 3.32.6 toolchain.
- Commits and pushes the changes.

On a pull request, GitHub Actions checks that:

- Release-prep regression tests pass.
- All package versions match `version.config`.
- All internal dependencies, including the standalone web viewer, are consistent.
- The changelog contains the current version.
- Generated README files and `llms.txt` match their sources.

## Internal dependencies

The system manages dependencies between ISpect packages:

- When you bump the version, internal dependencies (`ispectify: ^7.0.0` and similar) are updated.
- All packages end up using the same version of every other internal package.
- Run `dart run tool/bin/ispect_tool.dart deps` to verify dependency consistency.

## Best practices

1. Use `ispect_tool release-prep` for bumps and `ispect_tool release-prep --skip-bump` for no-bump synchronization.
2. Edit release notes only in the root `CHANGELOG.md`.
3. Edit README content only under `docs/readme/**`.
4. Review the generated diff and run `ispect_tool publish --dry-run` before publishing.

For more detail, see [`VERSION_MANAGEMENT.md`](./VERSION_MANAGEMENT.md).
