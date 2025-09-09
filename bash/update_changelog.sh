#!/usr/bin/env bash
# Sync / propagate CHANGELOG entries to package changelogs.
# Usage examples:
#   ./bash/update_changelog.sh                # propagate latest version section only (non‑destructive)
#   ./bash/update_changelog.sh --full-copy    # overwrite each package CHANGELOG with root (asks confirmation unless --yes)
#   ./bash/update_changelog.sh --version 4.3.6 # ensure version 4.3.6 section exists in every package (copies from root)
#   ./bash/update_changelog.sh --help

set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MAIN_CHANGELOG="CHANGELOG.md"
if [[ ! -f $MAIN_CHANGELOG ]]; then
    echo "[ERR] Root $MAIN_CHANGELOG not found" >&2; exit 1
fi

MODE_FULL_COPY=0
FORCE_YES=0
TARGET_VERSION=""

usage() {
    cat <<USAGE
update_changelog.sh - propagate changelog entries to packages

Options:
    --full-copy        Overwrite each package CHANGELOG with the root one
    --yes              Don't ask for confirmation when using --full-copy
    --version <ver>    Only propagate (or append) a specific version section
    --help             Show this help

Default (no flags): propagate ONLY the most recent version section (safe).
USAGE
}

while [[ ${1:-} != "" ]]; do
    case "$1" in
        --full-copy) MODE_FULL_COPY=1 ;;
        --yes) FORCE_YES=1 ;;
        --version) shift; TARGET_VERSION="${1:-}" ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
    esac
    shift || true
done

# Extract latest version section from root changelog
extract_section() { # $1=version
    local ver="$1"
    awk -v ver="## ${ver}" 'BEGIN{found=0} /^## / { if(found) exit } $0==ver {found=1} found' "$MAIN_CHANGELOG"
}

latest_version() {
    grep '^## ' "$MAIN_CHANGELOG" | head -1 | sed 's/^## \([^ ]*\).*/\1/'
}

if [[ -z $TARGET_VERSION ]]; then
    TARGET_VERSION="$(latest_version)"
fi

if ! grep -q "^## $TARGET_VERSION" "$MAIN_CHANGELOG"; then
    echo "[ERR] Version $TARGET_VERSION not found in root CHANGELOG" >&2; exit 1
fi

LATEST_BLOCK="$(extract_section "$TARGET_VERSION")"
if [[ -z $LATEST_BLOCK ]]; then
    echo "[ERR] Could not extract section for $TARGET_VERSION" >&2; exit 1
fi

confirm() { # $1=prompt
    local prompt="$1"
    if [[ $FORCE_YES -eq 1 ]]; then return 0; fi
    read -r -p "$prompt [y/N] " ans
    [[ $ans =~ ^[Yy]$ ]]
}

overwrite_copy() {
    local pkg_changelog="$1"
    cp "$MAIN_CHANGELOG" "$pkg_changelog"
    echo "[OK] Overwrote $pkg_changelog"
}

ensure_section_present() {
    local pkg_changelog="$1"
    if grep -q "^## $TARGET_VERSION" "$pkg_changelog"; then
        echo "[SKIP] $pkg_changelog already has $TARGET_VERSION"
    else
        printf '\n%s\n' "$LATEST_BLOCK" >> "$pkg_changelog"
        echo "[OK] Appended $TARGET_VERSION to $pkg_changelog"
    fi
}

echo "[INFO] Root version target: $TARGET_VERSION"

if [[ $MODE_FULL_COPY -eq 1 ]]; then
    confirm "This will overwrite all package CHANGELOG.md files" || { echo "Aborted"; exit 0; }
fi

for dir in packages/*/; do
    [[ -d $dir ]] || continue
    pkg_changelog="${dir}CHANGELOG.md"
    if [[ ! -f $pkg_changelog ]]; then
        echo "[MISS] $pkg_changelog (skipping)"; continue
    fi
    if [[ $MODE_FULL_COPY -eq 1 ]]; then
        overwrite_copy "$pkg_changelog"
    else
        ensure_section_present "$pkg_changelog"
    fi
done

echo "[DONE] Changelog propagation complete"
