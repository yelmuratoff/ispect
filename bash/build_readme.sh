#!/usr/bin/env bash
# build_readme.sh — assemble per-package READMEs from docs/readme/ sources.
#
# Sources live in docs/readme/:
#   <package>.md      body for each package
#   root.md           body for the repo-root README.md
#   _partials/*.md    reusable fragments
#
# Markers handled during build:
#   <!-- partial:NAME -->   → replaced by docs/readme/_partials/NAME.md
#   {{version}}             → VERSION from version.config
#   {{package}}             → target package name (root uses "ispect")
#
# Usage:
#   ./bash/build_readme.sh                 generate all READMEs
#   ./bash/build_readme.sh --check         verify generated files are up to date (CI)
#   ./bash/build_readme.sh --package NAME  rebuild a single package
#   ./bash/build_readme.sh --dry-run       show what would change without writing
#
# Exit codes:
#   0  success (or --check with no drift)
#   1  drift detected in --check mode
#   2  usage / configuration error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$ROOT_DIR/docs/readme"
PARTIALS_DIR="$SRC_DIR/_partials"
VERSION_CONFIG="$ROOT_DIR/version.config"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

# Targets: "<source-name>:<output-path>:<package-name>"
TARGETS=(
  "root:$ROOT_DIR/README.md:ispect"
  "ispect:$ROOT_DIR/packages/ispect/README.md:ispect"
  "ispect_layout:$ROOT_DIR/packages/ispect_layout/README.md:ispect_layout"
  "ispectify:$ROOT_DIR/packages/ispectify/README.md:ispectify"
  "ispectify_bloc:$ROOT_DIR/packages/ispectify_bloc/README.md:ispectify_bloc"
  "ispectify_db:$ROOT_DIR/packages/ispectify_db/README.md:ispectify_db"
  "ispectify_dio:$ROOT_DIR/packages/ispectify_dio/README.md:ispectify_dio"
  "ispectify_http:$ROOT_DIR/packages/ispectify_http/README.md:ispectify_http"
  "ispectify_riverpod:$ROOT_DIR/packages/ispectify_riverpod/README.md:ispectify_riverpod"
  "ispectify_ws:$ROOT_DIR/packages/ispectify_ws/README.md:ispectify_ws"
)

MODE="build"
FILTER_PACKAGE=""

usage() {
  sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)    MODE="check"; shift ;;
    --dry-run)  MODE="dry-run"; shift ;;
    --package)  FILTER_PACKAGE="${2:-}"; shift 2 ;;
    -h|--help)  usage ;;
    *)          echo "${RED}Unknown option: $1${NC}" >&2; usage ;;
  esac
done

# --- Validation ---
if [[ ! -f "$VERSION_CONFIG" ]]; then
  echo "${RED}error: version.config not found at $VERSION_CONFIG${NC}" >&2
  exit 2
fi

VERSION="$(grep -E '^VERSION=' "$VERSION_CONFIG" | head -n1 | cut -d= -f2-)"
if [[ -z "$VERSION" ]]; then
  echo "${RED}error: VERSION missing in version.config${NC}" >&2
  exit 2
fi

if [[ ! -d "$SRC_DIR" ]]; then
  echo "${RED}error: source directory missing: $SRC_DIR${NC}" >&2
  exit 2
fi

# --- Rendering ---
# expand_partials <src-file> <depth> → stdout
# Recursively expands `<!-- partial:NAME -->` markers. A partial may itself
# reference other partials (e.g. the shared `root_body` partial pulls in
# header/install_matrix/production_safety/footer).
expand_partials() {
  local src="$1" depth="${2:-0}"
  local line partial_name partial_path

  if (( depth > 16 )); then
    echo "${RED}error: partial recursion too deep (>16) while processing $src${NC}" >&2
    exit 2
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*\<!--[[:space:]]*partial:([A-Za-z0-9_]+)[[:space:]]*--\>[[:space:]]*$ ]]; then
      partial_name="${BASH_REMATCH[1]}"
      partial_path="$PARTIALS_DIR/$partial_name.md"
      if [[ ! -f "$partial_path" ]]; then
        echo "${RED}error: unknown partial '$partial_name' referenced in $src${NC}" >&2
        exit 2
      fi
      expand_partials "$partial_path" $((depth + 1))
      # Keep a blank line after the partial for breathing room.
      echo ""
    else
      printf '%s\n' "$line"
    fi
  done < "$src"
}

# render_template <src-file> <package-name> → stdout
render_template() {
  local src="$1" pkg="$2"
  expand_partials "$src" 0 | awk -v ver="$VERSION" -v pkg="$pkg" '
    {
      gsub(/\{\{version\}\}/, ver)
      gsub(/\{\{package\}\}/, pkg)
      print
    }
  '
}

render_target() {
  local src_name="$1" out_path="$2" pkg="$3"
  local src_file="$SRC_DIR/$src_name.md"

  if [[ ! -f "$src_file" ]]; then
    echo "${RED}error: source missing: $src_file${NC}" >&2
    exit 2
  fi

  {
    printf '%s\n' "<!--"
    printf '%s\n' "  GENERATED FILE — do not edit by hand."
    printf '%s\n' "  Source:     docs/readme/$src_name.md"
    printf '%s\n' "  Regenerate: ./bash/build_readme.sh"
    printf '%s\n' "-->"
    printf '\n'
    render_template "$src_file" "$pkg"
  }
}

# --- Drift comparison ---
# Normalise a README for comparison by stripping the GENERATED banner block
# (lines 1–6 plus the trailing blank line). Prevents meaningless diffs if the
# banner text ever changes without a content change.
strip_banner() {
  tail -n +8 "$1"
}

compare_or_write() {
  local src_name="$1" out_path="$2" pkg="$3" label
  label="$(basename "$(dirname "$out_path")")"
  [[ "$out_path" == "$ROOT_DIR/README.md" ]] && label="<root>"

  local rendered
  rendered="$(render_target "$src_name" "$out_path" "$pkg")"

  case "$MODE" in
    check)
      if [[ ! -f "$out_path" ]]; then
        echo "${RED}✗${NC} $label — missing (expected generated README at $out_path)"
        return 1
      fi
      local tmp
      tmp="$(mktemp)"
      printf '%s\n' "$rendered" > "$tmp"
      if ! diff -q <(strip_banner "$out_path") <(strip_banner "$tmp") >/dev/null; then
        echo "${RED}✗${NC} $label — drift detected"
        diff -u <(strip_banner "$out_path") <(strip_banner "$tmp") | head -n 40 || true
        rm -f "$tmp"
        return 1
      fi
      rm -f "$tmp"
      echo "${GREEN}✓${NC} $label"
      ;;
    dry-run)
      echo "${BLUE}would write${NC} $out_path ($(printf '%s\n' "$rendered" | wc -l | tr -d ' ') lines)"
      ;;
    build)
      printf '%s\n' "$rendered" > "$out_path"
      echo "${GREEN}✓${NC} $label → $out_path"
      ;;
  esac
}

# --- Main loop ---
header() {
  case "$MODE" in
    check)   echo "${YELLOW}Checking generated READMEs against sources…${NC}";;
    dry-run) echo "${YELLOW}Dry run — no files will be written.${NC}";;
    build)   echo "${YELLOW}Building READMEs (version $VERSION)…${NC}";;
  esac
  echo ""
}
header

fail=0
matched=0
for entry in "${TARGETS[@]}"; do
  IFS=':' read -r src_name out_path pkg <<<"$entry"
  if [[ -n "$FILTER_PACKAGE" && "$pkg" != "$FILTER_PACKAGE" && "$src_name" != "$FILTER_PACKAGE" ]]; then
    continue
  fi
  matched=$((matched + 1))
  if ! compare_or_write "$src_name" "$out_path" "$pkg"; then
    fail=$((fail + 1))
  fi
done

if [[ -n "$FILTER_PACKAGE" && "$matched" -eq 0 ]]; then
  echo "${RED}error: no target matches --package $FILTER_PACKAGE${NC}" >&2
  exit 2
fi

echo ""
if [[ "$MODE" == "check" ]]; then
  if [[ "$fail" -gt 0 ]]; then
    echo "${RED}README drift detected in $fail target(s). Run ./bash/build_readme.sh to sync.${NC}"
    exit 1
  fi
  echo "${GREEN}All generated READMEs are up to date.${NC}"
elif [[ "$MODE" == "build" ]]; then
  echo "${GREEN}Built $matched README(s).${NC}"
else
  echo "${BLUE}Dry run complete.${NC}"
fi
