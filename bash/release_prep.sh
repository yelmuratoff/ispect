#!/usr/bin/env bash
# release_prep.sh - one-shot release preparation.
#
# Default flow (non-interactive, always runs top to bottom):
#   1. Bump version in version.config and all pubspecs (skip with --skip-bump).
#   2. Ensure root CHANGELOG.md has a section for the new version
#      (inserts an empty stub near the top if missing).
#   3. Propagate root CHANGELOG.md to every package.
#   4. Rebuild per-package READMEs from docs/readme/.
#   5. Run `dart format .` on the tree.
#
# Typical flow:
#   ./bash/release_prep.sh
#       bump patch + stub + propagate + README + format
#   ... edit CHANGELOG.md, fill in the stub with real entries ...
#   ./bash/release_prep.sh --skip-bump
#       sync current version across packages/README + re-propagate
#       CHANGELOG + rebuild READMEs + format (no version bump)
#   ./bash/release_prep.sh --carry-changelog
#       bump version and rename current CHANGELOG section
#       to the new version instead of inserting a fresh stub
#
# Options:
#   patch|minor|major     Bump kind (default: patch). Ignored with --skip-bump.
#   --skip-bump           Keep current version, just sync it across
#                         pubspecs/README and refresh docs.
#   --carry-changelog     After bump, rename the previous version section in
#                         CHANGELOG.md to the new version (useful for devXX -> devYY).
#   --edit                Open $EDITOR on CHANGELOG.md between stub-insert and propagate.
#   --help                Show this help.
#
# Each step remains independently runnable:
#   ./bash/update_versions.sh --bump patch
#   ./bash/update_changelog.sh --full-copy --yes
#   ./bash/build_readme.sh
#   dart format .

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUMP_KIND="patch"
SKIP_BUMP=0
OPEN_EDITOR=0
CARRY_CHANGELOG=0

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    patch|minor|major) BUMP_KIND="$arg" ;;
    --skip-bump)       SKIP_BUMP=1 ;;
    --carry-changelog|--rename-current-changelog)
                       CARRY_CHANGELOG=1 ;;
    --edit)            OPEN_EDITOR=1 ;;
    --help|-h)         usage; exit 0 ;;
    *) echo "[ERR] Unknown argument: $arg" >&2; usage; exit 2 ;;
  esac
done

CHANGELOG="CHANGELOG.md"
VERSION_FILE="version.config"

# Read current version before any bump.
# shellcheck disable=SC1090
source "$VERSION_FILE"
PREVIOUS_VERSION="$VERSION"

if [[ $SKIP_BUMP -eq 1 && $CARRY_CHANGELOG -eq 1 ]]; then
  echo "[ERR] --carry-changelog cannot be combined with --skip-bump" >&2
  exit 2
fi

# 1. Bump version (or just sync the current one across packages/README)
if [[ $SKIP_BUMP -eq 0 ]]; then
  echo "==> Bumping version ($BUMP_KIND)"
  ./bash/update_versions.sh --bump "$BUMP_KIND"
else
  echo "==> Skipping version bump; syncing current version across packages"
  ./bash/update_versions.sh
fi

# Read current version (post-bump or unchanged)
# shellcheck disable=SC1090
source "$VERSION_FILE"
NEW_VERSION="$VERSION"
echo "==> Target version: $NEW_VERSION"

# 2. Ensure root CHANGELOG has a section for NEW_VERSION
section_present() {
  grep -qE "^## ${NEW_VERSION}([[:space:]]|$)" "$CHANGELOG"
}

previous_section_present() {
  grep -qE "^## ${PREVIOUS_VERSION}([[:space:]]|$)" "$CHANGELOG"
}

rename_previous_section() {
  awk -v old="## ${PREVIOUS_VERSION}" -v new="## ${NEW_VERSION}" '
    BEGIN { replaced=0 }
    !replaced && $0 == old { print new; replaced=1; next }
    { print }
  ' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
}

insert_stub() {
  local stub_file
  stub_file=$(mktemp)
  cat > "$stub_file" <<MARKDOWN

## ${NEW_VERSION}

### Added

-

### Improvements

-

### Bug Fixes

-

MARKDOWN
  awk -v sf="$stub_file" '
    NR==1 {
      print
      while ((getline line < sf) > 0) print line
      close(sf)
      next
    }
    { print }
  ' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
  rm -f "$stub_file"
}

if section_present; then
  echo "==> $CHANGELOG already has a section for $NEW_VERSION"
elif [[ $CARRY_CHANGELOG -eq 1 ]] &&
     [[ $PREVIOUS_VERSION != "$NEW_VERSION" ]] &&
     previous_section_present; then
  echo "==> Renaming CHANGELOG section $PREVIOUS_VERSION -> $NEW_VERSION"
  rename_previous_section
else
  echo "==> Inserting stub section for $NEW_VERSION in $CHANGELOG"
  insert_stub
fi

# Optional: open editor (non-fatal — failures don't abort the rest)
if [[ $OPEN_EDITOR -eq 1 ]]; then
  EDITOR_CMD="${EDITOR:-}"
  if [[ -z $EDITOR_CMD ]]; then
    if   command -v code >/dev/null 2>&1; then EDITOR_CMD="code --wait"
    elif command -v vim  >/dev/null 2>&1; then EDITOR_CMD="vim"
    elif command -v nano >/dev/null 2>&1; then EDITOR_CMD="nano"
    fi
  fi
  if [[ -n $EDITOR_CMD ]]; then
    echo "==> Opening $CHANGELOG ($EDITOR_CMD) - save & close to continue"
    # shellcheck disable=SC2086
    $EDITOR_CMD "$CHANGELOG" || echo "[WARN] Editor exited non-zero; continuing anyway"
  else
    echo "[WARN] No editor found; skipping"
  fi
fi

# 3. Propagate CHANGELOG to packages
echo "==> Propagating CHANGELOG to packages"
./bash/update_changelog.sh --full-copy --yes

# 4. Rebuild READMEs
echo "==> Rebuilding READMEs"
./bash/build_readme.sh

# 5. Format
echo "==> Formatting Dart sources"
dart format .

echo "==> Done (version: $NEW_VERSION)"
