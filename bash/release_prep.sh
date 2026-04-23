#!/usr/bin/env bash
# release_prep.sh - one-shot release preparation.
#
# Default flow:
#   1. Bump version in version.config and all pubspecs.
#   2. Ensure root CHANGELOG.md has a section for the new version
#      (inserts a stub near the top if missing).
#   3. Open $EDITOR on CHANGELOG.md so you can finalize the entry.
#   4. Propagate root CHANGELOG.md to every package.
#   5. Rebuild per-package READMEs from docs/readme/.
#   6. Run `dart format .` on the tree.
#
# Usage:
#   ./bash/release_prep.sh                  # default: bump patch + full flow
#   ./bash/release_prep.sh minor            # same, minor bump
#   ./bash/release_prep.sh major            # same, major bump
#   ./bash/release_prep.sh --skip-bump      # keep current version, just sync docs
#   ./bash/release_prep.sh --no-edit        # auto-insert stub, don't open editor
#   ./bash/release_prep.sh --help
#
# Each underlying step can also be run independently:
#   ./bash/update_versions.sh --bump patch
#   ./bash/update_changelog.sh --full-copy --yes
#   ./bash/build_readme.sh
#   dart format .

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUMP_KIND="patch"
SKIP_BUMP=0
NO_EDIT=0

usage() {
  sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    patch|minor|major) BUMP_KIND="$arg" ;;
    --skip-bump)       SKIP_BUMP=1 ;;
    --no-edit)         NO_EDIT=1 ;;
    --help|-h)         usage; exit 0 ;;
    *) echo "[ERR] Unknown argument: $arg" >&2; usage; exit 2 ;;
  esac
done

CHANGELOG="CHANGELOG.md"
VERSION_FILE="version.config"

# 1. Bump version
if [[ $SKIP_BUMP -eq 0 ]]; then
  echo "==> Bumping version ($BUMP_KIND)"
  ./bash/update_versions.sh --bump "$BUMP_KIND"
else
  echo "==> Skipping version bump"
fi

# Read (possibly new) version
# shellcheck disable=SC1090
source "$VERSION_FILE"
NEW_VERSION="$VERSION"
echo "==> Target version: $NEW_VERSION"

# 2. Ensure root CHANGELOG has a section for NEW_VERSION
section_present() {
  grep -qE "^## ${NEW_VERSION}([[:space:]]|$)" "$CHANGELOG"
}

insert_stub() {
  local stub
  stub=$(cat <<MARKDOWN
## ${NEW_VERSION}

### Added

-

### Improvements

-

### Bug Fixes

-

MARKDOWN
)
  awk -v stub="$stub" '
    NR==1 { print; print ""; print stub; next }
    { print }
  ' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
}

if [[ $SKIP_BUMP -eq 0 ]]; then
  if section_present; then
    echo "==> $CHANGELOG already has a section for $NEW_VERSION"
  else
    echo "==> Inserting stub section for $NEW_VERSION in $CHANGELOG"
    insert_stub
  fi

  # 3. Open editor unless --no-edit
  if [[ $NO_EDIT -eq 0 ]]; then
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
      $EDITOR_CMD "$CHANGELOG"
    else
      echo "[WARN] No editor found (\$EDITOR unset, no code/vim/nano); skipping edit step"
    fi
  fi
fi

# 4. Propagate CHANGELOG to packages
echo "==> Propagating CHANGELOG to packages"
./bash/update_changelog.sh --full-copy --yes

# 5. Rebuild READMEs
echo "==> Rebuilding READMEs"
./bash/build_readme.sh

# 6. Format
echo "==> Formatting Dart sources"
dart format .

echo "==> Done (version: $NEW_VERSION)"
