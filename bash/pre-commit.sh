#!/bin/bash
# pre-commit.sh - Git pre-commit hook to check version sync and dependencies
# To install: cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

echo "🔍 Checking version synchronization..."

# Run version sync check
./bash/check_version_sync.sh

# If the check fails, stop the commit
if [ $? -ne 0 ]; then
  echo "❌ Version check failed. Please run './bash/update_versions.sh' to sync all package versions."
  exit 1
fi

echo "🔍 Checking dependency consistency..."

# Run dependencies check
./bash/check_dependencies.sh

# If the dependency check fails, stop the commit
if [ $? -ne 0 ]; then
  echo "❌ Dependency check failed. Please run './bash/update_versions.sh' to sync all package dependencies."
  exit 1
fi

# Check CHANGELOG structure (optional)
if [ -f "CHANGELOG.md" ]; then
  if ! grep -q "^# Changelog" "CHANGELOG.md"; then
    echo "⚠️ CHANGELOG.md does not start with '# Changelog'. Please fix the format."
    exit 1
  fi
  
  # Check if current version exists in CHANGELOG
  if [ -f "version.config" ]; then
    source "version.config"
    if [ -n "$VERSION" ] && ! grep -q "^## $VERSION" "CHANGELOG.md"; then
      echo "⚠️ Current version $VERSION is not documented in CHANGELOG.md. Please update the changelog."
      exit 1
    fi
  fi
fi

echo "✅ Pre-commit checks passed!"
exit 0
