#!/usr/bin/env bash
# update_versions.sh - Robust multi-package version & internal dependency updater.
# Features:
#   - Reads VERSION from version.config
#   - --bump (patch|minor|major) auto-calculates next version & writes version.config
#   - Updates internal dependency constraints (^VERSION)
#   - Updates examples
#   - Dry-run mode
#   - Summary output

set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION_FILE="version.config"
if [[ ! -f $VERSION_FILE ]]; then
  echo "[ERR] $VERSION_FILE not found" >&2; exit 1
fi

source "$VERSION_FILE" || { echo "[ERR] Failed to source $VERSION_FILE" >&2; exit 1; }
if [[ -z ${VERSION:-} ]]; then
  echo "[ERR] VERSION not defined in $VERSION_FILE" >&2; exit 1
fi

DRY_RUN=0
BUMP_KIND=""

usage() {
  cat <<USAGE
update_versions.sh - sync versions across packages

Usage: ./bash/update_versions.sh [--dry-run] [--bump patch|minor|major]

Options:
  --dry-run           Show changes without modifying files
  --bump <kind>       Compute next semantic version and persist (patch|minor|major)
  --help              Show this help
Current VERSION: $VERSION
USAGE
}

semver_bump() { # $1=version $2=kind
  local v=$1 kind=$2
  local major minor patch
  IFS='.' read -r major minor patch <<<"$v"
  case $kind in
    patch) patch=$((patch+1)) ;;
    minor) minor=$((minor+1)); patch=0 ;;
    major) major=$((major+1)); minor=0; patch=0 ;;
    *) echo "[ERR] Unknown bump kind: $kind" >&2; return 1 ;;
  esac
  echo "${major}.${minor}.${patch}"
}

while [[ ${1:-} != "" ]]; do
  case $1 in
    --dry-run) DRY_RUN=1 ;;
    --bump) shift; BUMP_KIND="${1:-}" ;;
    --help|-h) usage; exit 0 ;;
    *) echo "[ERR] Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
  shift || true
done

if [[ -n $BUMP_KIND ]]; then
  NEW_VERSION=$(semver_bump "$VERSION" "$BUMP_KIND")
  echo "[INFO] Bump $BUMP_KIND: $VERSION -> $NEW_VERSION"
  if [[ $DRY_RUN -eq 0 ]]; then
    if sed -e "s/^VERSION=.*/VERSION=$NEW_VERSION/" "$VERSION_FILE" > "${VERSION_FILE}.tmp" && mv "${VERSION_FILE}.tmp" "$VERSION_FILE"; then
      VERSION=$NEW_VERSION
    else
      echo "[ERR] Failed writing new version" >&2; exit 1
    fi
  fi
fi

echo "[INFO] Target version: $VERSION (dry-run=$DRY_RUN)"

PACKAGE_DIRS=()
while IFS= read -r line; do
  PACKAGE_DIRS+=("$line")
done < <(find packages -maxdepth 1 -mindepth 1 -type d | sort)
declare -a PACKAGE_NAMES=()
for dir in "${PACKAGE_DIRS[@]}"; do
  ps="$dir/pubspec.yaml"
  [[ -f $ps ]] || continue
  name=$(grep -E '^name:' "$ps" | awk '{print $2}')
  PACKAGE_NAMES+=("$name")
done
echo "[INFO] Packages: ${PACKAGE_NAMES[*]}"

change_files=()

replace_version_line() { # $1=file
  local file="$1"
  local current
  current=$(grep -E '^version:' "$file" | awk '{print $2}') || true
  if [[ $current != "$VERSION" ]]; then
    echo "[CHG] $file version $current -> $VERSION"
    if [[ $DRY_RUN -eq 0 ]]; then
      sed -e "s/^version:.*/version: $VERSION/" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
      change_files+=("$file")
    fi
  else
    echo "[OK ] $file already $VERSION"
  fi
}

update_internal_refs() { # $1=file
  local file="$1" updated=0
  for pkg in "${PACKAGE_NAMES[@]}"; do
    # Only adjust lines inside dependencies or dev_dependencies
    if grep -q "^  $pkg: \^" "$file"; then
      if ! grep -q "^  $pkg: \^$VERSION" "$file"; then
        echo "[CHG] $file -> $pkg ^$VERSION"
        if [[ $DRY_RUN -eq 0 ]]; then
          # Use awk to scope modifications
          awk -v pkg="$pkg" -v ver="$VERSION" '
            BEGIN { in_section=0 }
            /^[a-z]/ { in_section=0 }
            /^dependencies:/ { in_section=1 }
            /^dev_dependencies:/ { in_section=1 }
            in_section && $0 ~ "^  "pkg": \\^" { print "  "pkg": ^"ver; next }
            { print }
          ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
          updated=1
        fi
      fi
    fi
  done
  if [[ $updated -eq 1 ]]; then change_files+=("$file"); fi
}

# Process each package
for dir in "${PACKAGE_DIRS[@]}"; do
  ps="$dir/pubspec.yaml"
  [[ -f $ps ]] || continue
  replace_version_line "$ps"
  update_internal_refs "$ps"

  # Example project
  ex_ps="$dir/example/pubspec.yaml"
  if [[ -f $ex_ps ]]; then
    update_internal_refs "$ex_ps"
  fi
done

echo "[INFO] Summary:" 
if [[ ${#change_files[@]} -gt 0 ]]; then
  printf '  - %s\n' "${change_files[@]}"
else
  echo "  (no file changes)"
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DONE] Dry-run completed"
else
  echo "[DONE] Version update completed"
fi
