#!/usr/bin/env bash
# Sync README.md from workspace root to all packages
# Usage: ./bash/update_readme.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

# Simply call the sync_readme.sh script
exec "$SCRIPT_DIR/sync_readme.sh" "$@"
