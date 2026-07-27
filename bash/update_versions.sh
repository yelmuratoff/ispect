#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION_FILE="version.config"
DRY_RUN=0
BUMP_KIND=""
WEB_LOCKFILE=""
WEB_LOCKFILE_TMP=""
WEB_LOCKFILE_NEXT_TMP=""
WEB_LOCKFILE_CHANGED=0
WRITE_TMP_FILES=()

cleanup() {
  local status=$?
  local temp_file
  trap - EXIT
  if [[ ${#WRITE_TMP_FILES[@]} -gt 0 ]]; then
    for temp_file in "${WRITE_TMP_FILES[@]}"; do
      if [[ -f $temp_file ]]; then
        rm -f -- "$temp_file"
      fi
    done
  fi
  if [[ -n $WEB_LOCKFILE_TMP && -f $WEB_LOCKFILE_TMP ]]; then
    rm -f -- "$WEB_LOCKFILE_TMP"
  fi
  if [[ -n $WEB_LOCKFILE_NEXT_TMP && -f $WEB_LOCKFILE_NEXT_TMP ]]; then
    rm -f -- "$WEB_LOCKFILE_NEXT_TMP"
  fi
  exit "$status"
}
trap cleanup EXIT

if [[ ! -f $VERSION_FILE ]]; then
  echo "[ERR] $VERSION_FILE not found" >&2
  exit 1
fi

VERSION=$(awk -F= '$1 == "VERSION" { print substr($0, index($0, "=") + 1); exit }' "$VERSION_FILE")
if [[ -z ${VERSION:-} ]]; then
  echo "[ERR] VERSION not defined in $VERSION_FILE" >&2
  exit 1
fi
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$ ]]; then
  echo "[ERR] Invalid VERSION in $VERSION_FILE: $VERSION" >&2
  exit 1
fi

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

semver_bump() {
  local value="$1"
  local kind="$2"
  local core="$value"
  local prerelease=""
  local major
  local minor
  local patch

  if [[ $value == *-* ]]; then
    core="${value%%-*}"
    prerelease="${value#*-}"
  fi
  if [[ ! $core =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "[ERR] Invalid semantic version: $value" >&2
    return 1
  fi
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"

  case $kind in
    patch)
      if [[ -n $prerelease && $prerelease =~ ^([A-Za-z]+)(\.?)([0-9]+)$ ]]; then
        local label="${BASH_REMATCH[1]}"
        local separator="${BASH_REMATCH[2]}"
        local number="${BASH_REMATCH[3]}"
        local width="${#number}"
        local next_number=$((10#$number + 1))
        local padded_number
        printf -v padded_number "%0${width}d" "$next_number"
        echo "${major}.${minor}.${patch}-${label}${separator}${padded_number}"
        return 0
      fi
      patch=$((10#$patch + 1))
      ;;
    minor)
      minor=$((10#$minor + 1))
      patch=0
      prerelease=""
      ;;
    major)
      major=$((10#$major + 1))
      minor=0
      patch=0
      prerelease=""
      ;;
    *)
      echo "[ERR] Unknown bump kind: $kind" >&2
      return 1
      ;;
  esac

  if [[ -n $prerelease ]]; then
    echo "${major}.${minor}.${patch}-${prerelease}"
  else
    echo "${major}.${minor}.${patch}"
  fi
}

while [[ ${1:-} != "" ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=1
      ;;
    --bump)
      shift
      if [[ -z ${1:-} ]]; then
        echo "[ERR] --bump requires patch, minor, or major" >&2
        exit 2
      fi
      BUMP_KIND="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[ERR] Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
  shift
done

ORIGINAL_VERSION="$VERSION"
if [[ -n $BUMP_KIND ]]; then
  VERSION=$(semver_bump "$ORIGINAL_VERSION" "$BUMP_KIND")
  echo "[INFO] Bump $BUMP_KIND: $ORIGINAL_VERSION -> $VERSION"
fi
echo "[INFO] Target version: $VERSION (dry-run=$DRY_RUN)"

PACKAGE_DIRS=()
while IFS= read -r line; do
  PACKAGE_DIRS+=("$line")
done < <(find packages -maxdepth 1 -mindepth 1 -type d | sort)

PACKAGE_NAMES=()
for dir in "${PACKAGE_DIRS[@]}"; do
  pubspec="$dir/pubspec.yaml"
  [[ -f $pubspec ]] || continue
  package_name=$(awk '$1 == "name:" { print $2; exit }' "$pubspec")
  if [[ -z $package_name ]]; then
    echo "[ERR] Package name not found in $pubspec" >&2
    exit 1
  fi
  PACKAGE_NAMES+=("$package_name")
done
if [[ ${#PACKAGE_NAMES[@]} -eq 0 ]]; then
  echo "[ERR] No package pubspecs found" >&2
  exit 1
fi

printf '[INFO] Packages:'
printf ' %s' "${PACKAGE_NAMES[@]}"
printf '\n'

change_files=()

web_has_local_path_ref() {
  local manifest="$1"
  local package_name="$2"

  awk -v package_name="$package_name" '
    $0 == "  " package_name ":" {
      in_package = 1
      next
    }
    in_package && /^  [^ ]/ {
      in_package = 0
    }
    in_package && /^    path:[[:space:]]*[^[:space:]]/ {
      found = 1
    }
    END {
      exit found ? 0 : 1
    }
  ' "$manifest"
}

lockfile_has_one_valid_path_stanza() {
  local lockfile="$1"
  local package_name="$2"

  awk -v package_name="$package_name" '
    $0 == "  " package_name ":" {
      stanza_count++
      in_stanza = 1
      next
    }
    in_stanza && /^  [^ ]/ {
      in_stanza = 0
    }
    in_stanza && /^    source:[[:space:]]*/ {
      source_count++
      source = $2
      gsub(/"/, "", source)
      if (source == "path") {
        path_source_count++
      }
    }
    in_stanza && /^    version:[[:space:]]*/ {
      version_count++
    }
    END {
      valid = stanza_count == 1 &&
        source_count == 1 &&
        path_source_count == 1 &&
        version_count == 1
      exit valid ? 0 : 1
    }
  ' "$lockfile"
}

rewrite_lockfile_package_version() {
  local input="$1"
  local output="$2"
  local package_name="$3"

  cp -p "$input" "$output"
  awk -v package_name="$package_name" -v version="$VERSION" '
    $0 == "  " package_name ":" {
      in_stanza = 1
      print
      next
    }
    in_stanza && /^  [^ ]/ {
      in_stanza = 0
    }
    in_stanza && /^    version:[[:space:]]*/ {
      print "    version: \"" version "\""
      next
    }
    {
      print
    }
  ' "$input" > "$output"
}

prepare_web_lockfile() {
  local manifest="web_logs_viewer/pubspec.yaml"
  local lockfile="web_logs_viewer/pubspec.lock"
  local package_name
  local path_package_names=()

  [[ -f $manifest ]] || return 0
  for package_name in "${PACKAGE_NAMES[@]}"; do
    if web_has_local_path_ref "$manifest" "$package_name"; then
      path_package_names+=("$package_name")
    fi
  done
  if [[ ${#path_package_names[@]} -eq 0 ]]; then
    return 0
  fi
  if [[ ! -f $lockfile ]]; then
    echo "[ERR] $lockfile is required for local web path dependencies" >&2
    exit 1
  fi

  WEB_LOCKFILE="$lockfile"
  WEB_LOCKFILE_TMP=$(mktemp "${lockfile}.tmp.XXXXXX")
  WEB_LOCKFILE_NEXT_TMP="${WEB_LOCKFILE_TMP}.next"
  cp -p "$lockfile" "$WEB_LOCKFILE_TMP"

  for package_name in "${path_package_names[@]}"; do
    if ! lockfile_has_one_valid_path_stanza "$WEB_LOCKFILE_TMP" "$package_name"; then
      echo "[ERR] Invalid path package stanza in $lockfile: $package_name" >&2
      exit 1
    fi
    rewrite_lockfile_package_version \
      "$WEB_LOCKFILE_TMP" \
      "$WEB_LOCKFILE_NEXT_TMP" \
      "$package_name"
    mv "$WEB_LOCKFILE_NEXT_TMP" "$WEB_LOCKFILE_TMP"
  done

  if cmp -s "$lockfile" "$WEB_LOCKFILE_TMP"; then
    echo "[OK ] $lockfile path package versions already $VERSION"
  else
    WEB_LOCKFILE_CHANGED=1
    change_files+=("$lockfile")
    echo "[CHG] $lockfile path package versions -> $VERSION"
  fi
}

replace_version_line() {
  local file="$1"
  local current
  local temp_file

  current=$(awk '$1 == "version:" { print $2; exit }' "$file")
  if [[ $current == "$VERSION" ]]; then
    echo "[OK ] $file already $VERSION"
    return 0
  fi

  echo "[CHG] $file version $current -> $VERSION"
  if [[ $DRY_RUN -eq 0 ]]; then
    temp_file=$(mktemp "${file}.tmp.XXXXXX")
    WRITE_TMP_FILES+=("$temp_file")
    cp -p "$file" "$temp_file"
    sed -e "s/^version:.*/version: $VERSION/" "$file" > "$temp_file"
    mv "$temp_file" "$file"
  fi
  change_files+=("$file")
}

update_internal_refs() {
  local file="$1"
  local package_name
  local updated=0
  local temp_file

  for package_name in "${PACKAGE_NAMES[@]}"; do
    if grep -Eq "^  ${package_name}: \\^" "$file" &&
      ! grep -Fqx "  ${package_name}: ^${VERSION}" "$file"; then
      echo "[CHG] $file -> $package_name ^$VERSION"
      updated=1
      if [[ $DRY_RUN -eq 0 ]]; then
        temp_file=$(mktemp "${file}.tmp.XXXXXX")
        WRITE_TMP_FILES+=("$temp_file")
        cp -p "$file" "$temp_file"
        awk -v package_name="$package_name" -v version="$VERSION" '
          /^[a-z]/ {
            in_dependency_section = 0
          }
          /^dependencies:/ || /^dev_dependencies:/ {
            in_dependency_section = 1
          }
          in_dependency_section && $0 ~ "^  " package_name ": \\^" {
            print "  " package_name ": ^" version
            next
          }
          {
            print
          }
        ' "$file" > "$temp_file"
        mv "$temp_file" "$file"
      fi
    fi
  done

  if [[ $updated -eq 1 ]]; then
    change_files+=("$file")
  fi
}

apply_web_lockfile() {
  if [[ -z $WEB_LOCKFILE_TMP ]]; then
    return 0
  fi

  if [[ $WEB_LOCKFILE_CHANGED -eq 1 && $DRY_RUN -eq 0 ]]; then
    mv "$WEB_LOCKFILE_TMP" "$WEB_LOCKFILE"
  else
    rm -f -- "$WEB_LOCKFILE_TMP"
  fi
  WEB_LOCKFILE_TMP=""
}

prepare_web_lockfile

if [[ $ORIGINAL_VERSION != "$VERSION" ]]; then
  change_files+=("$VERSION_FILE")
  if [[ $DRY_RUN -eq 0 ]]; then
    version_temp_file=$(mktemp "${VERSION_FILE}.tmp.XXXXXX")
    WRITE_TMP_FILES+=("$version_temp_file")
    cp -p "$VERSION_FILE" "$version_temp_file"
    sed -e "s/^VERSION=.*/VERSION=$VERSION/" "$VERSION_FILE" > "$version_temp_file"
    mv "$version_temp_file" "$VERSION_FILE"
  fi
fi

for dir in "${PACKAGE_DIRS[@]}"; do
  pubspec="$dir/pubspec.yaml"
  [[ -f $pubspec ]] || continue
  replace_version_line "$pubspec"
  update_internal_refs "$pubspec"

  example_pubspec="$dir/example/pubspec.yaml"
  if [[ -f $example_pubspec ]]; then
    update_internal_refs "$example_pubspec"
  fi
done

PUBSPECS_WITH_PUBLISHED_CONSTRAINTS=(
  "web_logs_viewer/pubspec.yaml"
)
for pubspec in "${PUBSPECS_WITH_PUBLISHED_CONSTRAINTS[@]}"; do
  [[ -f $pubspec ]] || continue
  update_internal_refs "$pubspec"
done

apply_web_lockfile

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
