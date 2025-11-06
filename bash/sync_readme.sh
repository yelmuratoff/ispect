#!/bin/bash

# Sync README.md from workspace root to all packages
# Usage: ./bash/sync_readme.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
ROOT_README="$WORKSPACE_ROOT/README.md"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if root README exists
if [ ! -f "$ROOT_README" ]; then
    echo -e "${RED}Error: Root README.md not found at $ROOT_README${NC}"
    exit 1
fi

echo -e "${GREEN}Syncing README.md from workspace root to all packages...${NC}"
echo ""

# Array of package directories
PACKAGES=(
    "ispect"
    "ispectify"
    "ispectify_bloc"
    "ispectify_db"
    "ispectify_dio"
    "ispectify_http"
    "ispectify_ws"
)

# Counter for synced packages
synced_count=0

# Copy README to each package
for package in "${PACKAGES[@]}"; do
    package_dir="$WORKSPACE_ROOT/packages/$package"
    target_readme="$package_dir/README.md"
    
    if [ -d "$package_dir" ]; then
        cp "$ROOT_README" "$target_readme"
        echo -e "${GREEN}✓${NC} Synced README to packages/$package"
        ((synced_count++))
    else
        echo -e "${YELLOW}⚠${NC} Package directory not found: packages/$package"
    fi
done

echo ""
echo -e "${GREEN}Successfully synced README to $synced_count packages${NC}"
