# Version Management System

This document explains how the version management system works for this Flutter package.

## Files

- `version.config` - Single source of truth for the current version
- `bash/bump_version.sh` - Script to bump versions easily
- `bash/update_versions.sh` - Script to sync all package versions and internal package dependencies
- `bash/update_changelog.sh` - Script to sync all changelog files
- `bash/check_version_sync.sh` - Script to validate version synchronization
- `bash/check_dependencies.sh` - Script to validate internal package dependencies are consistent
- `bash/pre-commit.sh` - Git hook to ensure versions are in sync before commits
- `.github/workflows/sync_versions_and_changelogs.yml` - CI/CD workflow for automatic version and changelog sync
- `.github/workflows/validate_versions.yml` - CI/CD workflow to validate versions in Pull Requests

## Usage

### Manual Version Management

To bump the version, run:

```bash
# Bump patch version (e.g., 4.1.2 -> 4.1.3)
./bash/bump_version.sh patch

# Bump minor version (e.g., 4.1.2 -> 4.2.0)
./bash/bump_version.sh minor

# Bump major version (e.g., 4.1.2 -> 5.0.0)
./bash/bump_version.sh major

# Bump dev version (e.g., 4.1.2 -> 4.1.2-dev01 or 4.1.2-dev01 -> 4.1.2-dev02)
./bash/bump_version.sh dev

# Set specific version
./bash/bump_version.sh 4.2.0-beta01
```

The `bump_version.sh` script will:
1. Update `version.config` with the new version
2. Run `update_versions.sh` to update all package versions and changelogs

### Automatic Updates via CI/CD

The GitHub Actions workflows provide several automation features:

#### Sync Versions and Changelogs
- Triggers when `version.config` or `CHANGELOG.md` is changed
- Updates all package versions based on `version.config` 
- Syncs the main changelog to all package changelogs
- Commits and pushes the changes back to the repository

#### Version Validation
- Runs on pull requests to main branches
- Validates that all package versions are in sync
- Ensures the CHANGELOG properly documents the current version

## How It Works

1. The `version.config` file contains a single VERSION variable
2. When you bump the version, all package `pubspec.yaml` files are updated
3. Internal package dependencies (e.g. `ispect` depends on `ispectify`) are updated to use the new version
4. The main `CHANGELOG.md` is kept as the source of truth for release notes
5. All package `CHANGELOG.md` files are synced with the main one
6. CI/CD ensures all versions, dependencies, and changelogs stay in sync

## Best Practices

1. Always use the bump_version.sh script to change versions
2. Update the main CHANGELOG.md before bumping versions 
3. Let the CI/CD handle the sync process
4. Install the pre-commit hook to catch version inconsistencies early
5. For larger teams, use the GitHub Actions manual version bump workflow
6. Check the git diff after CI/CD runs to ensure everything is updated correctly

## Pre-Commit Hook

A pre-commit hook is provided to ensure versions are in sync before committing:

```bash
# Install the pre-commit hook
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

This hook will:
1. Check that all package versions match version.config
2. Check that all internal dependencies are consistent with the current version
3. Validate CHANGELOG.md formatting
4. Ensure the current version is documented in the CHANGELOG

## Troubleshooting

If you encounter version sync issues:

1. Run `./bash/check_version_sync.sh` to identify out-of-sync packages
2. Run `./bash/check_dependencies.sh` to identify inconsistent dependencies between packages
3. Run `./bash/update_versions.sh` to sync all package versions and dependencies
4. If the CHANGELOG is missing your version, update it and re-run the above script
