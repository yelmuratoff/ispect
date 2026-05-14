# Version Management System

How versions are kept consistent across the ISpect monorepo.

## Files

- `version.config`, the single source of truth for the current version.
- `bash/bump_version.sh`, bumps versions.
- `bash/update_versions.sh`, syncs all package versions and internal package dependencies.
- `bash/update_changelog.sh`, syncs all changelog files.
- `bash/check_version_sync.sh`, validates version synchronization.
- `bash/check_dependencies.sh`, validates that internal package dependencies are consistent.
- `bash/pre-commit.sh`, Git hook that catches version drift before a commit lands.
- `.github/workflows/sync_versions_and_changelogs.yml`, CI workflow for automatic version and changelog sync.
- `.github/workflows/validate_versions.yml`, CI workflow that validates versions in pull requests.
- `.github/workflows/production_safety.yml`, CI workflow that verifies release builds with `ISPECT_ENABLED` omitted.

## Usage

### Manual version management

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

`bump_version.sh` does two things:

1. Updates `version.config` with the new version.
2. Runs `update_versions.sh` to update all package versions and changelogs.

### Automatic updates via CI/CD

The GitHub Actions workflows automate the rest.

`sync_versions_and_changelogs.yml`:

- Triggers when `version.config` or `CHANGELOG.md` changes.
- Updates all package versions to match `version.config`.
- Syncs the main changelog into every package changelog.
- Regenerates package README files from `docs/readme/`.
- Commits and pushes the changes back.

`validate_versions.yml`:

- Runs on pull requests to main branches.
- Checks that all package versions are in sync.
- Checks that `CHANGELOG.md` documents the current version.
- Checks that generated README files match their sources.

## How it works

1. `version.config` contains a single `VERSION` variable.
2. When you bump the version, every package `pubspec.yaml` is updated.
3. Internal dependencies between packages (for example `ispect` depending on `ispectify`) are updated to the new version.
4. The main `CHANGELOG.md` stays the source of truth for release notes.
5. Each package `CHANGELOG.md` is synced from the main one.
6. Package README files are regenerated from `docs/readme/`.
7. CI keeps versions, dependencies, changelogs, and READMEs aligned.

## Best practices

1. Bump versions only through `bump_version.sh`.
2. Update the main `CHANGELOG.md` before bumping versions.
3. Let CI handle the sync.
4. Install the pre-commit hook to catch version drift locally.
5. On larger teams, prefer the GitHub Actions manual version-bump workflow.
6. Check the diff after CI runs to confirm nothing was missed.

## Pre-commit hook

A pre-commit hook catches version drift before it lands:

```bash
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

The hook:

1. Checks that all package versions match `version.config`.
2. Checks that internal dependencies are consistent with the current version.
3. Validates `CHANGELOG.md` formatting.
4. Confirms the current version is documented in the changelog.

## Troubleshooting

If you hit a sync issue:

1. Run `./bash/check_version_sync.sh` to find out-of-sync packages.
2. Run `./bash/check_dependencies.sh` to find inconsistent dependencies between packages.
3. Run `./bash/update_versions.sh` to sync versions and dependencies.
4. If the changelog is missing your version, update it and rerun the script above.
