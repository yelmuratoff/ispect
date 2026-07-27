# ISpect Version Management

A short overview of the version-management workflow. The full reference lives in [`VERSION_MANAGEMENT.md`](./VERSION_MANAGEMENT.md).

## Tools and files

### Key files

- `version.config`, the single source of truth for the current version.
- `CHANGELOG.md`, the release notes for every version.
- `bash/release_prep.sh`, the single command for bumps and release synchronization.
- `bash/update_versions.sh`, `bash/update_changelog.sh`, `bash/build_readme.sh`, and `bash/build_llms.sh`, internal helpers used by `release_prep.sh`.
- `bash/check_version_sync.sh`, validates that versions are in sync.
- `bash/check_dependencies.sh`, validates that internal dependencies are consistent.

### GitHub Actions workflows

- `sync_versions_and_changelogs.yml`, syncs versions, dependencies, changelogs, and generated README files when sources change.
- `validate_versions.yml`, validates versions, dependencies, changelog entries, and generated README files in pull requests.
- `production_safety.yml`, runs the disabled API matrix and compares exact
  implementation sentinels in disabled and enabled release AOT builds.
- `test.yml`, runs analyze, tests, and coverage across packages.

## Version bump types

```bash
# Patch bump (default).
./bash/release_prep.sh

# Explicit patch, minor, or major bump.
./bash/release_prep.sh --bump major

# Keep VERSION and refresh all release-managed files.
./bash/release_prep.sh --skip-bump

# Advance a prerelease and keep its current changelog notes.
./bash/release_prep.sh --carry-changelog

# Resume an interrupted prerelease sync without another bump.
./bash/release_prep.sh --skip-bump --recover-changelog
```

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
- Run `./bash/check_dependencies.sh` to verify dependency consistency.

## Best practices

1. Use `release_prep.sh` for bumps and `release_prep.sh --skip-bump` for no-bump synchronization.
2. Edit release notes only in the root `CHANGELOG.md`.
3. Edit README content only under `docs/readme/**`.
4. Review the generated diff and run `publish.sh --dry-run` before publishing.

For more detail, see [`VERSION_MANAGEMENT.md`](./VERSION_MANAGEMENT.md).
