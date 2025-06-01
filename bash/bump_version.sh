#!/bin/bash
# bump_version.sh - Utility to easily bump version numbers
# Usage: ./bash/bump_version.sh [patch|minor|major|dev|<specific-version>]
# Example: ./bash/bump_version.sh patch
#          ./bash/bump_version.sh 4.2.0
#          ./bash/bump_version.sh dev

# Determine the directory where the script is located
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
root_dir="$(dirname "$script_dir")"
version_file="$root_dir/version.config"

# Source the current version
if [ -f "$version_file" ]; then
  source "$version_file"
elif [ -f "version.config" ]; then
  source "version.config"
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION not defined in version.config"
  exit 1
fi

# Function to extract version components
parse_version() {
  local version=$1
  
  # Handle dev versions like 4.1.3-dev09
  if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-dev([0-9]+))?$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    DEV_TAG="${BASH_REMATCH[4]}"
    DEV_NUM="${BASH_REMATCH[5]}"
    
    if [ -z "$DEV_NUM" ]; then
      DEV_NUM=0
    fi
  else
    echo "Error: Version format not recognized: $version"
    echo "Expected format: MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-devNN"
    exit 1
  fi
}

# Parse current version
parse_version "$VERSION"
echo "Current version: $VERSION (Major: $MAJOR, Minor: $MINOR, Patch: $PATCH, Dev: $DEV_TAG)"

# Handle version bump based on argument
if [ -z "$1" ]; then
  echo "Error: No version bump type specified"
  echo "Usage: ./bash/bump_version.sh [patch|minor|major|dev|<specific-version>]"
  exit 1
fi

case "$1" in
  "major")
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  "minor")
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  "patch")
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
  "dev")
    if [[ $VERSION =~ -dev ]]; then
      # Already a dev version, increment dev number
      NEW_DEV_NUM=$((DEV_NUM + 1))
      # Format with leading zero if single digit
      if [ "$NEW_DEV_NUM" -lt 10 ]; then
        NEW_DEV_NUM="0$NEW_DEV_NUM"
      fi
      NEW_VERSION="$MAJOR.$MINOR.$PATCH-dev$NEW_DEV_NUM"
    else
      # Convert to dev version
      NEW_VERSION="$MAJOR.$MINOR.$PATCH-dev01"
    fi
    ;;
  *)
    # Assume it's a specific version
    if [[ $1 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-dev([0-9]+))?$ ]]; then
      NEW_VERSION="$1"
    else
      echo "Error: Invalid version format: $1"
      echo "Expected format: MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-devNN"
      exit 1
    fi
    ;;
esac

echo "Bumping version to: $NEW_VERSION"

# Update version.config
echo "VERSION=$NEW_VERSION" > version.config
echo "Updated version.config"

# Run the version update script
if [ -f "bash/update_versions.sh" ]; then
  echo "Running update_versions.sh..."
  bash/update_versions.sh
else
  echo "Warning: update_versions.sh not found. Only version.config has been updated."
fi
