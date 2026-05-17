# ISpect Version Management

A short overview of the version-management workflow. The full reference lives in [`VERSION_MANAGEMENT.md`](./VERSION_MANAGEMENT.md).

## Tools and files

### Key files

- `version.config`, the single source of truth for the current version.
- `CHANGELOG.md`, the release notes for every version.
- `bash/bump_version.sh`, bumps versions.
- `bash/update_versions.sh`, updates all package versions and internal dependencies.
- `bash/update_changelog.sh`, syncs the main changelog to every package.
- `bash/check_version_sync.sh`, validates that versions are in sync.
- `bash/check_dependencies.sh`, validates that internal dependencies are consistent.

### GitHub Actions workflows

- `sync_versions_and_changelogs.yml`, syncs versions, dependencies, changelogs, and generated README files when sources change.
- `validate_versions.yml`, validates versions, dependencies, changelog entries, and generated README files in pull requests.
- `production_safety.yml`, builds a release APK without `ISPECT_ENABLED` and counts residual ISpect strings.
- `test.yml`, runs analyze, tests, and coverage across packages.

## Version bump types

```bash
# Bump patch version (4.1.2 -> 4.1.3).
./bash/bump_version.sh patch

# Bump minor version (4.1.2 -> 4.2.0).
./bash/bump_version.sh minor

# Bump major version (4.1.2 -> 5.0.0).
./bash/bump_version.sh major

# Bump dev version (4.1.2 -> 4.1.2-dev01, or 4.1.2-dev01 -> 4.1.2-dev02).
./bash/bump_version.sh dev

# Set a specific version.
./bash/bump_version.sh 4.2.0-beta01
```

## CI process

When you update `CHANGELOG.md` or `version.config`, GitHub Actions automatically:

- Updates all package versions to match `version.config`.
- Updates all internal dependencies between packages to the same version.
- Updates all example project dependencies.
- Copies the main changelog into every package changelog.
- Regenerates package README files from `docs/readme/`.
- Commits and pushes the changes.

On a pull request, GitHub Actions checks that:

- All package versions match `version.config`.
- All internal dependencies are consistent.
- The changelog contains the current version.
- Generated README files match their sources.

## Internal dependencies

The system manages dependencies between ISpect packages:

- When you bump the version, internal dependencies (`ispectify: ^4.1.3-dev09` and similar) are updated.
- All packages end up using the same version of every other internal package.
- Run `./bash/check_dependencies.sh` to verify dependency consistency.

## Best practices

1. Update `CHANGELOG.md` before bumping versions.
2. Use `bump_version.sh` locally.
3. For releases, prefer the GitHub Actions workflow for consistency.
4. Check the Git diff after a version bump to confirm everything updated.

For more detail, see [`VERSION_MANAGEMENT.md`](./VERSION_MANAGEMENT.md).
