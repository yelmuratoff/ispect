#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION_FILE="version.config"
CHANGELOG_FILE="CHANGELOG.md"
TEMP_ROOT="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
BUMP_KIND="patch"
BUMP_WAS_EXPLICIT=0
SKIP_BUMP=0
CARRY_CHANGELOG=0
RECOVER_CHANGELOG=0
OPEN_EDITOR=0
SNAPSHOT_DIR=""
TRANSACTION_STARTED=0
TRANSACTION_COMMITTED=0
EDITED_CHANGELOG_BACKUP=""
RELEASE_TARGETS=()

usage() {
  cat <<'USAGE'
release_prep.sh - synchronize every release-managed artifact

Usage:
  ./bash/release_prep.sh [patch|minor|major] [options]
  ./bash/release_prep.sh --bump patch|minor|major [options]
  ./bash/release_prep.sh --skip-bump [options]

Modes:
  patch|minor|major     Bump kind (default: patch)
  --bump <kind>        Explicit bump kind (patch, minor, or major)
  --skip-bump          Keep VERSION and synchronize every derived artifact
  --no-bump            Alias for --skip-bump

Options:
  --carry-changelog    Move the previous prerelease notes to the next prerelease
  --recover-changelog  Resume an interrupted prerelease sync without a bump
  --edit               Open CHANGELOG.md before generating derived artifacts
  --help               Show this help

The command updates version metadata, internal constraints, the web viewer
lockfile, root and package changelogs, generated READMEs, and llms.txt. It then
validates the complete result. If any step fails, all managed files are restored
to their exact pre-run state.
USAGE
}

fail() {
  echo "[ERR] $*" >&2
  exit 1
}

read_version() {
  local value
  [[ -f $VERSION_FILE ]] || fail "$VERSION_FILE not found"
  value=$(awk -F= '$1 == "VERSION" { print substr($0, index($0, "=") + 1); exit }' "$VERSION_FILE")
  [[ $value =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$ ]] ||
    fail "Invalid VERSION in $VERSION_FILE: ${value:-<empty>}"
  printf '%s\n' "$value"
}

collect_release_targets() {
  local package_dir
  local relative_path

  RELEASE_TARGETS=(
    "$VERSION_FILE"
    "$CHANGELOG_FILE"
    "README.md"
    "llms.txt"
    "web_logs_viewer/pubspec.yaml"
    "web_logs_viewer/pubspec.lock"
  )

  for package_dir in packages/*; do
    [[ -d $package_dir ]] || continue
    for relative_path in \
      pubspec.yaml \
      CHANGELOG.md \
      README.md \
      example/pubspec.yaml; do
      RELEASE_TARGETS+=("$package_dir/$relative_path")
    done
  done
}

path_has_symlink_ancestor() {
  local ancestor

  ancestor=$(dirname "$1")
  while [[ $ancestor != "." && $ancestor != "/" ]]; do
    if [[ -L $ancestor ]]; then
      return 0
    fi
    ancestor=$(dirname "$ancestor")
  done
  return 1
}

validate_release_targets() {
  local target
  local ancestor

  for target in "${RELEASE_TARGETS[@]}"; do
    case $target in
      /*|../*|*/../*|*/..)
        fail "Managed path escapes the repository: $target"
        ;;
    esac
    if [[ -L $target ]] || path_has_symlink_ancestor "$target"; then
      fail "Managed paths cannot contain symlinks: $target"
    fi
    if [[ -e $target && ! -f $target ]]; then
      fail "Managed target must be a regular file: $target"
    fi

    ancestor=$(dirname "$target")
    while [[ $ancestor != "." && $ancestor != "/" ]]; do
      if [[ -e $ancestor && ! -d $ancestor ]]; then
        fail "Managed path parent must be a directory: $ancestor"
      fi
      ancestor=$(dirname "$ancestor")
    done
  done
}

snapshot_release_targets() {
  local target
  local snapshot_path

  SNAPSHOT_DIR=$(mktemp -d "$TEMP_ROOT/ispect-release-prep.XXXXXX")
  mkdir -p "$SNAPSHOT_DIR/files"
  : > "$SNAPSHOT_DIR/existing"

  for target in "${RELEASE_TARGETS[@]}"; do
    if [[ -e $target || -L $target ]]; then
      snapshot_path="$SNAPSHOT_DIR/files/$target"
      mkdir -p "$(dirname "$snapshot_path")"
      cp -pP "$target" "$snapshot_path"
      printf '%s\n' "$target" >> "$SNAPSHOT_DIR/existing"
    fi
  done

  TRANSACTION_STARTED=1
}

restore_release_targets() {
  local target
  local snapshot_path
  local restore_failed=0
  local existed_before
  local grep_status

  if [[ ! -r $SNAPSHOT_DIR/existing ]]; then
    echo "[ERR] Recovery snapshot manifest is not readable" >&2
    return 1
  fi

  for target in "${RELEASE_TARGETS[@]}"; do
    snapshot_path="$SNAPSHOT_DIR/files/$target"
    existed_before=0
    if grep -Fqx -- "$target" "$SNAPSHOT_DIR/existing"; then
      existed_before=1
    else
      grep_status=$?
      if [[ $grep_status -ne 1 ]]; then
        echo "[ERR] Cannot read recovery metadata for $target" >&2
        restore_failed=1
        continue
      fi
    fi
    if path_has_symlink_ancestor "$target"; then
      echo "[ERR] Cannot safely restore through a symlink: $target" >&2
      restore_failed=1
      continue
    fi
    if [[ $existed_before -eq 1 ]]; then
      if ! mkdir -p "$(dirname "$target")"; then
        echo "[ERR] Cannot recreate parent directory for $target" >&2
        restore_failed=1
        continue
      fi
    fi
    if [[ -e $target || -L $target ]]; then
      if [[ -d $target && ! -L $target ]]; then
        echo "[ERR] Cannot replace directory while restoring $target" >&2
        restore_failed=1
        continue
      fi
      if ! rm -f -- "$target"; then
        echo "[ERR] Cannot remove changed target during rollback: $target" >&2
        restore_failed=1
        continue
      fi
    fi

    if [[ $existed_before -eq 1 ]]; then
      if ! cp -p "$snapshot_path" "$target"; then
        echo "[ERR] Cannot restore $target from snapshot" >&2
        restore_failed=1
      fi
    fi
  done

  return "$restore_failed"
}

cleanup_snapshot() {
  if [[ -n $SNAPSHOT_DIR && -d $SNAPSHOT_DIR ]]; then
    case $SNAPSHOT_DIR in
      "$TEMP_ROOT"/ispect-release-prep.*)
        rm -rf -- "$SNAPSHOT_DIR"
        ;;
      *)
        echo "[ERR] Refusing to remove unexpected snapshot path: $SNAPSHOT_DIR" >&2
        return 1
        ;;
    esac
  fi
}

on_exit() {
  local status=$?
  local keep_snapshot=0

  trap - EXIT
  trap '' INT TERM HUP
  if [[ $TRANSACTION_STARTED -eq 1 && $TRANSACTION_COMMITTED -eq 0 ]]; then
    echo "[WARN] Release preparation failed; restoring the pre-run state" >&2
    if ! restore_release_targets; then
      echo "[ERR] Automatic rollback failed" >&2
      echo "[INFO] Recovery snapshot retained at $SNAPSHOT_DIR" >&2
      status=1
      keep_snapshot=1
    fi
    if [[ -n $EDITED_CHANGELOG_BACKUP && -f $EDITED_CHANGELOG_BACKUP ]]; then
      echo "[INFO] Edited changelog preserved at $EDITED_CHANGELOG_BACKUP" >&2
      EDITED_CHANGELOG_BACKUP=""
    fi
  fi

  if [[ $keep_snapshot -eq 0 ]]; then
    if ! cleanup_snapshot; then
      status=1
    fi
  fi
  if [[ -n $EDITED_CHANGELOG_BACKUP && -f $EDITED_CHANGELOG_BACKUP ]]; then
    rm -f -- "$EDITED_CHANGELOG_BACKUP"
  fi
  exit "$status"
}

section_count() {
  local version="$1"
  awk -v heading="## $version" '$0 == heading { count++ } END { print count + 0 }' "$CHANGELOG_FILE"
}

latest_section_version() {
  awk '
    /^## / {
      sub(/^## /, "")
      print
      exit
    }
  ' "$CHANGELOG_FILE"
}

is_next_prerelease() {
  local previous="$1"
  local current="$2"
  local previous_core
  local previous_label
  local previous_separator
  local previous_digits
  local current_core
  local current_label
  local current_separator
  local current_digits
  local previous_number
  local current_number

  if [[ $previous =~ ^([0-9]+\.[0-9]+\.[0-9]+)-([A-Za-z]+)(\.?)([0-9]+)$ ]]; then
    previous_core="${BASH_REMATCH[1]}"
    previous_label="${BASH_REMATCH[2]}"
    previous_separator="${BASH_REMATCH[3]}"
    previous_digits="${BASH_REMATCH[4]}"
  else
    return 1
  fi

  if [[ $current =~ ^([0-9]+\.[0-9]+\.[0-9]+)-([A-Za-z]+)(\.?)([0-9]+)$ ]]; then
    current_core="${BASH_REMATCH[1]}"
    current_label="${BASH_REMATCH[2]}"
    current_separator="${BASH_REMATCH[3]}"
    current_digits="${BASH_REMATCH[4]}"
  else
    return 1
  fi

  [[ $previous_core == "$current_core" ]] || return 1
  [[ $previous_label == "$current_label" ]] || return 1
  [[ $previous_separator == "$current_separator" ]] || return 1

  previous_number=$((10#$previous_digits))
  current_number=$((10#$current_digits))
  [[ $current_number -eq $((previous_number + 1)) ]]
}

rename_changelog_section() {
  local previous="$1"
  local current="$2"
  local next_changelog="$SNAPSHOT_DIR/changelog.next"

  awk -v old="## $previous" -v new="## $current" '
    $0 == old {
      replacements++
      print new
      next
    }
    { print }
    END {
      if (replacements != 1) exit 1
    }
  ' "$CHANGELOG_FILE" > "$next_changelog"
  cp "$next_changelog" "$CHANGELOG_FILE"
}

insert_changelog_stub() {
  local version="$1"
  local next_changelog="$SNAPSHOT_DIR/changelog.next"

  awk -v version="$version" '
    NR == 1 {
      print
      print ""
      print "## " version
      print ""
      print "### Added"
      print ""
      print "-"
      print ""
      print "### Improvements"
      print ""
      print "-"
      print ""
      print "### Bug Fixes"
      print ""
      print "-"
      next
    }
    { print }
  ' "$CHANGELOG_FILE" > "$next_changelog"
  cp "$next_changelog" "$CHANGELOG_FILE"
}

sync_changelog_heading() {
  local previous_version="$1"
  local target_version="$2"
  local target_count
  local previous_count
  local latest_version

  target_count=$(section_count "$target_version")
  [[ $target_count -le 1 ]] ||
    fail "$CHANGELOG_FILE contains duplicate sections for $target_version"

  if [[ $RECOVER_CHANGELOG -eq 1 ]]; then
    [[ $target_count -eq 0 ]] ||
      fail "--recover-changelog requires the target section to be missing"
    latest_version=$(latest_section_version)
    [[ $(section_count "$latest_version") -eq 1 ]] ||
      fail "Expected exactly one $latest_version section to recover"
    is_next_prerelease "$latest_version" "$target_version" ||
      fail "--recover-changelog requires the immediately previous prerelease"
    echo "==> Recovering interrupted changelog sync: $latest_version -> $target_version"
    rename_changelog_section "$latest_version" "$target_version"
  elif [[ $target_count -eq 1 ]]; then
    [[ $CARRY_CHANGELOG -eq 0 ]] ||
      fail "Cannot carry notes: $CHANGELOG_FILE already contains $target_version"
  elif [[ $CARRY_CHANGELOG -eq 1 ]]; then
    is_next_prerelease "$previous_version" "$target_version" ||
      fail "--carry-changelog only supports the next prerelease of the same channel"
    previous_count=$(section_count "$previous_version")
    [[ $previous_count -eq 1 ]] ||
      fail "Expected exactly one $previous_version section to carry"
    echo "==> Moving changelog notes: $previous_version -> $target_version"
    rename_changelog_section "$previous_version" "$target_version"
  elif [[ $SKIP_BUMP -eq 1 ]]; then
    echo "==> Adding changelog section for $target_version"
    insert_changelog_stub "$target_version"
  else
    echo "==> Adding changelog section for $target_version"
    insert_changelog_stub "$target_version"
  fi

  latest_version=$(latest_section_version)
  [[ $latest_version == "$target_version" ]] ||
    fail "The first changelog section must be $target_version, found ${latest_version:-none}"
}

open_changelog_editor() {
  local editor_value="${EDITOR:-}"
  local editor_command=()
  local editor_status=0
  local editor_signal_status=0
  local backup_candidate
  local backup_status=0

  if [[ -n $editor_value ]]; then
    IFS=$' \t' read -r -a editor_command <<< "$editor_value"
  elif command -v code >/dev/null 2>&1; then
    editor_command=(code --wait)
  elif command -v vim >/dev/null 2>&1; then
    editor_command=(vim)
  elif command -v nano >/dev/null 2>&1; then
    editor_command=(nano)
  else
    fail "No editor found; set EDITOR or omit --edit"
  fi

  echo "==> Opening $CHANGELOG_FILE; save and close to continue"
  trap 'editor_signal_status=130' INT
  trap 'editor_signal_status=143' TERM
  trap 'editor_signal_status=129' HUP
  backup_candidate=$(mktemp "$TEMP_ROOT/ispect-changelog-edit.XXXXXX")
  if "${editor_command[@]}" "$CHANGELOG_FILE"; then
    editor_status=0
  else
    editor_status=$?
  fi
  if cp "$CHANGELOG_FILE" "$backup_candidate"; then
    EDITED_CHANGELOG_BACKUP="$backup_candidate"
  else
    backup_status=$?
  fi
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
  if [[ $backup_status -ne 0 ]]; then
    rm -f -- "$backup_candidate"
    fail "Failed to preserve edited changelog"
  fi
  if [[ $editor_signal_status -ne 0 ]]; then
    exit "$editor_signal_status"
  fi
  [[ $editor_status -eq 0 ]] ||
    fail "Editor exited with a non-zero status"
}

validate_package_changelogs() {
  local package_changelog

  for package_changelog in packages/*/CHANGELOG.md; do
    [[ -f $package_changelog ]] || continue
    cmp -s "$CHANGELOG_FILE" "$package_changelog" ||
      fail "$package_changelog differs from $CHANGELOG_FILE"
  done
}

validate_release() {
  local target_version="$1"
  local target_count

  echo "==> Validating release artifacts"
  ./bash/check_version_sync.sh
  ./bash/check_dependencies.sh
  ./bash/build_readme.sh --check
  ./bash/build_llms.sh --check

  target_count=$(section_count "$target_version")
  [[ $target_count -eq 1 ]] ||
    fail "$CHANGELOG_FILE must contain exactly one $target_version section"
  [[ $(latest_section_version) == "$target_version" ]] ||
    fail "$target_version must be the first changelog section"
  validate_package_changelogs
}

while [[ $# -gt 0 ]]; do
  case $1 in
    patch|minor|major)
      [[ $BUMP_WAS_EXPLICIT -eq 0 ]] ||
        fail "Specify the bump kind only once"
      BUMP_KIND="$1"
      BUMP_WAS_EXPLICIT=1
      ;;
    --bump)
      [[ $BUMP_WAS_EXPLICIT -eq 0 ]] ||
        fail "Specify the bump kind only once"
      shift
      [[ ${1:-} == "patch" || ${1:-} == "minor" || ${1:-} == "major" ]] ||
        fail "--bump requires patch, minor, or major"
      BUMP_KIND="$1"
      BUMP_WAS_EXPLICIT=1
      ;;
    --skip-bump|--no-bump)
      SKIP_BUMP=1
      ;;
    --carry-changelog|--rename-current-changelog)
      CARRY_CHANGELOG=1
      ;;
    --recover-changelog)
      RECOVER_CHANGELOG=1
      ;;
    --edit)
      OPEN_EDITOR=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[ERR] Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

[[ $SKIP_BUMP -eq 0 || $BUMP_WAS_EXPLICIT -eq 0 ]] ||
  fail "A bump kind cannot be combined with --skip-bump"
[[ $SKIP_BUMP -eq 0 || $CARRY_CHANGELOG -eq 0 ]] ||
  fail "--carry-changelog cannot be combined with --skip-bump"
[[ $RECOVER_CHANGELOG -eq 0 || $SKIP_BUMP -eq 1 ]] ||
  fail "--recover-changelog requires --skip-bump"
[[ -f $CHANGELOG_FILE ]] || fail "$CHANGELOG_FILE not found"
[[ $(head -n 1 "$CHANGELOG_FILE") == "# Changelog" ]] ||
  fail "$CHANGELOG_FILE must start with '# Changelog'"

for helper in \
  bash/update_versions.sh \
  bash/update_changelog.sh \
  bash/build_readme.sh \
  bash/build_llms.sh \
  bash/check_version_sync.sh \
  bash/check_dependencies.sh; do
  [[ -x $helper ]] || fail "Required executable not found: $helper"
done

PREVIOUS_VERSION=$(read_version)
collect_release_targets
validate_release_targets
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
snapshot_release_targets

if [[ $SKIP_BUMP -eq 1 ]]; then
  echo "==> Synchronizing current version: $PREVIOUS_VERSION"
  ./bash/update_versions.sh
else
  echo "==> Bumping version ($BUMP_KIND): $PREVIOUS_VERSION"
  ./bash/update_versions.sh --bump "$BUMP_KIND"
fi

TARGET_VERSION=$(read_version)
echo "==> Target version: $TARGET_VERSION"
sync_changelog_heading "$PREVIOUS_VERSION" "$TARGET_VERSION"

if [[ $OPEN_EDITOR -eq 1 ]]; then
  open_changelog_editor
fi

echo "==> Synchronizing package changelogs"
./bash/update_changelog.sh --full-copy --yes

echo "==> Generating READMEs"
./bash/build_readme.sh

echo "==> Generating llms.txt"
./bash/build_llms.sh

validate_release "$TARGET_VERSION"

TRANSACTION_COMMITTED=1
echo "==> Release artifacts are synchronized (version: $TARGET_VERSION)"
