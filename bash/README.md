# Git Hooks for ISpect

This directory contains Git hooks to help maintain code quality and consistency.

## Available Hooks

### Pre-Commit Hook

The pre-commit hook performs the following checks:
- Ensures all package versions are in sync with version.config
- Verifies that internal dependencies between packages use consistent versions
- Validates CHANGELOG.md format
- Verifies the current version exists in the CHANGELOG

## Installation

To install the pre-commit hook, run:

```bash
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

## Manual Usage

You can also run the checks manually:

```bash
# Check version synchronization
./bash/check_version_sync.sh

# Check dependency consistency between packages
./bash/check_dependencies.sh

# Update versions and dependencies if needed
./bash/update_versions.sh

# Bump version (patch, minor, major, dev, or specific version)
./bash/bump_version.sh patch
```
