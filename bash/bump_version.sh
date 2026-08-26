#!/usr/bin/env bash
# bump_version.sh - legacy bump helper kept for backward compatibility.
# Usage: ./bash/bump_version.sh [patch|minor|major|dev|<specific-version>]
# Example: ./bash/bump_version.sh dev
#          ./bash/bump_version.sh 7.1.0
# Prefer ./bash/release_prep.sh, which also synchronizes changelogs and READMEs.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/bash/lib/semver.sh"

VERSION_FILE="version.config"

usage() {
  cat <<'USAGE'
bump_version.sh - bump VERSION and synchronize package versions

Usage: ./bash/bump_version.sh [patch|minor|major|dev|<specific-version>]

  patch|minor|major   Delegated to ./bash/update_versions.sh --bump <kind>
  dev                 Advance the prerelease counter, or open a new prerelease
                      series on the next patch (7.1.0 -> 7.1.1-dev.1)
  <specific-version>  Any semantic version that Pub orders above the current one
USAGE
}

if [[ ! -f $VERSION_FILE ]]; then
  echo "[ERR] $VERSION_FILE not found" >&2
  exit 1
fi

VERSION=$(awk -F= '$1 == "VERSION" { print substr($0, index($0, "=") + 1); exit }' "$VERSION_FILE")
if ! semver_is_valid "$VERSION"; then
  echo "[ERR] Invalid VERSION in $VERSION_FILE: ${VERSION:-<empty>}" >&2
  exit 1
fi

if [[ -z ${1:-} ]]; then
  echo "[ERR] No version bump type specified" >&2
  usage >&2
  exit 2
fi

echo "[INFO] Current version: $VERSION"

case "$1" in
  patch | minor | major)
    exec bash/update_versions.sh --bump "$1"
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  dev)
    if [[ -n $(semver_prerelease "$VERSION") ]]; then
      NEW_VERSION=$(semver_next_prerelease "$VERSION")
    else
      IFS='.' read -r major minor patch <<<"$(semver_core "$VERSION")"
      NEW_VERSION=$(semver_start_prerelease "$major.$minor.$((10#$patch + 1))" dev)
    fi
    ;;
  *)
    if ! semver_is_valid "$1"; then
      echo "[ERR] Invalid version format: $1" >&2
      usage >&2
      exit 2
    fi
    NEW_VERSION="$1"
    ;;
esac

if ! semver_is_greater "$NEW_VERSION" "$VERSION"; then
  echo "[ERR] Pub does not order $NEW_VERSION above the current $VERSION" >&2
  exit 1
fi

echo "[INFO] Bumping version to: $NEW_VERSION"
version_temp_file=$(mktemp "${VERSION_FILE}.tmp.XXXXXX")
trap 'rm -f -- "$version_temp_file"' EXIT
cp -p "$VERSION_FILE" "$version_temp_file"
sed -e "s/^VERSION=.*/VERSION=$NEW_VERSION/" "$VERSION_FILE" > "$version_temp_file"
mv "$version_temp_file" "$VERSION_FILE"
trap - EXIT
echo "[INFO] Updated $VERSION_FILE"

exec bash/update_versions.sh
