#!/usr/bin/env bash
# update_readme.sh — regenerate per-package READMEs from docs/readme/ sources.
# Thin wrapper around build_readme.sh for symmetry with update_versions.sh / update_changelog.sh.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/build_readme.sh" "$@"
