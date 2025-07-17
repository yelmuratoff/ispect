# ISpect Version Management

This document provides an overview of the version management system for the ISpect project.

## Tools and Files

### Key Files
- `version.config` - The single source of truth for the current version
- `CHANGELOG.md` - Contains the release notes for all versions
- `bash/bump_version.sh` - Script to easily bump versions
- `bash/update_versions.sh` - Script to update all package versions and internal dependencies
- `bash/update_changelog.sh` - Script to sync the main changelog to all packages
- `bash/check_version_sync.sh` - Script to validate versions are in sync
- `bash/check_dependencies.sh` - Script to validate internal dependencies are consistent

### GitHub Actions Workflows
- `update_changelogs.yml` - Automatically syncs versions, dependencies and changelogs when updated
- `validate_versions.yml` - Validates versions and dependencies in pull requests

## Version Bump Types

You can use the following commands to bump the version:

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

## CI/CD Process

1. When you update the `CHANGELOG.md` or `version.config`, GitHub Actions will automatically:
   - Update all package versions to match version.config
   - Update all internal dependencies between packages to use the same version
   - Update all example project dependencies
   - Copy the main changelog to all package changelogs
   - Commit and push the changes

2. Pull request validation:
   - When you open a PR to main branches, GitHub Actions will check:
   - All package versions match version.config
   - All internal dependencies are consistent
   - The CHANGELOG contains the current version

## Internal Dependencies

The system automatically manages dependencies between ISpect packages:

- When you bump the version, all internal dependencies (like `ispectify: ^4.1.3-dev09`) are updated
- This ensures all packages use consistent versions of other internal packages
- You can run `./bash/check_dependencies.sh` to verify dependency consistency

## Best Practices

1. Always update the `CHANGELOG.md` before bumping versions
2. Use the bump_version.sh script for local development
3. For releases, consider using the GitHub Actions workflow for consistency
4. Check the Git diff after version bumps to ensure everything is updated correctly

For more detailed information, see the [VERSION_MANAGEMENT.md](./VERSION_MANAGEMENT.md) file.
