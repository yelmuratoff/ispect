#!/usr/bin/env bash
# Publish all Dart packages in correct dependency order.
# Usage:
#   chmod +x bash/publish.sh
#   ./bash/publish.sh                # dry-run each, then ask confirmation, then publish
#   ./bash/publish.sh --dry-run      # only dry-run
#   ./bash/publish.sh --auto         # no prompts, real publish (uses --force)
#   PUBLISH_FORCE=1 ./bash/publish.sh --auto  # same
#
# Options can be combined: --auto implies real publish; --dry-run overrides to only dry-run.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PACKAGES=(
	ispectify          # base logging
	ispectify_bloc     # depends on ispectify
	ispectify_dio      # depends on ispectify
	ispectify_http     # depends on ispectify
	ispectify_ws       # depends on ispectify
   ispectify_db      # depends on ispectify
	ispect             # core panel depends on ispectify + integrations (dev)
	ispect_jira        # optional addon
)

MODE_DRY_RUN=0
MODE_AUTO=0
MODE_VERBOSE=0

for arg in "$@"; do
	case "$arg" in
		--dry-run) MODE_DRY_RUN=1 ;;
		--auto) MODE_AUTO=1 ;;
	--verbose|-v) MODE_VERBOSE=1 ;;
		*) echo "Unknown option: $arg" >&2; exit 2 ;;
	esac
done

COLOR_YELLOW='\033[33m'
COLOR_GREEN='\033[32m'
COLOR_RED='\033[31m'
COLOR_RESET='\033[0m'

info()  { echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"; }
warn()  { echo -e "${COLOR_YELLOW}[..]${COLOR_RESET} $*"; }
error() { echo -e "${COLOR_RED}[ERR]${COLOR_RESET} $*"; }

VERSION_FILE="version.config"
if [[ ! -f $VERSION_FILE ]]; then
	error "version.config not found"; exit 1
fi
PROJECT_VERSION=$(grep '^VERSION=' "$VERSION_FILE" | cut -d'=' -f2 | tr -d '[:space:]')
warn "Project version: $PROJECT_VERSION"

# Failure tracking
FAIL_PKGS=()
FAIL_REASONS=()
LOG_DIR="$ROOT_DIR/.publish_logs"
rm -rf "$LOG_DIR" 2>/dev/null || true
mkdir -p "$LOG_DIR"

check_versions() {
	local mismatches=0
	for pkg in "${PACKAGES[@]}"; do
		local ps="packages/$pkg/pubspec.yaml"
		if [[ ! -f $ps ]]; then
			error "Missing pubspec for $pkg"; exit 1
		fi
		local ver
		ver=$(grep -E '^version:' "$ps" | head -1 | awk '{print $2}')
		if [[ "$ver" != "$PROJECT_VERSION" ]]; then
			error "$pkg version $ver != $PROJECT_VERSION"; mismatches=1
		fi
	done
	if [[ $mismatches -eq 1 ]]; then
		error "Version mismatch. Run ./bash/update_versions.sh first."; exit 1
	fi
	info "All package versions match $PROJECT_VERSION"
}

ensure_clean_git() {
	if ! git diff --quiet || ! git diff --cached --quiet; then
		warn "Uncommitted changes detected.";
	fi
}

# Preflight validation: ensure no 'any' constraints and no disallowed lockfiles in packages.
preflight_validate() {
	local bad=0
	for pkg in "${PACKAGES[@]}"; do
		local ps="packages/$pkg/pubspec.yaml"
		if grep -E '^[[:space:]]+[a-zA-Z0-9_]+: any$' "$ps" >/dev/null; then
			error "'$pkg' has unconstrained dependencies (uses 'any'). Replace them with ^version ranges."; bad=1
		fi
		# Disallow committed platform lockfiles inside example folders (Podfile.lock etc.)
		if git ls-files -- "packages/$pkg/**/Podfile.lock" | grep . >/dev/null; then
			error "'$pkg' contains a committed Podfile.lock. Remove it (platform lockfiles shouldn't be published)."; bad=1
		fi
	done
	if [[ $bad -eq 1 ]]; then
		error "Preflight validation failed. Fix issues above before publishing."; exit 1
	fi
	info "Preflight validation passed."
}

run_format() {
	warn "Formatting..."
	dart format . >/dev/null
}

publish_pkg() {
	local pkg="$1"
	local path="packages/$pkg"
	pushd "$path" >/dev/null

	warn "($pkg) pub get"
	dart pub get >/dev/null

		warn "($pkg) dart pub publish --dry-run"
		local dry_output
		if ! dry_output=$(dart pub publish --dry-run 2>&1); then
			local log_file="$LOG_DIR/${pkg}_dry_run.log"
			printf '%s\n' "$dry_output" > "$log_file"
			# Try to extract a concise reason line
			local reason
			reason=$(printf '%s\n' "$dry_output" | grep -E '^(Because|Error:|ERR |Package validation)|^\* ' | head -1)
			if [[ -z "$reason" ]]; then
				reason=$(printf '%s' "$dry_output" | head -1)
			fi
			FAIL_PKGS+=("$pkg")
			FAIL_REASONS+=("$reason")
			error "Dry-run failed for $pkg: $reason"
			if [[ $MODE_VERBOSE -eq 1 ]]; then
				echo -e "${COLOR_RED}---- FULL DRY-RUN OUTPUT ($pkg) ----${COLOR_RESET}"
				printf '%s\n' "$dry_output"
				echo -e "${COLOR_RED}------------------------------------${COLOR_RESET}"
			else
				warn "Full log: $log_file"
			fi
			popd >/dev/null; return 1
		else
			[[ $MODE_VERBOSE -eq 1 ]] && printf '%s\n' "$dry_output"
			info  "($pkg) dry-run OK"
		fi

	if [[ $MODE_DRY_RUN -eq 1 ]]; then
		popd >/dev/null; return 0
	fi

	if [[ $MODE_AUTO -eq 0 && -z "${PUBLISH_FORCE:-}" ]]; then
		read -r -p "Publish $pkg? [y/N] " ans
		[[ "$ans" =~ ^[Yy]$ ]] || { warn "Skip $pkg"; popd >/dev/null; return 0; }
	fi

	warn "($pkg) publishing..."
	if dart pub publish --force; then
		info "($pkg) published"
	else
		error "($pkg) publish failed"; popd >/dev/null; return 1
	fi

	popd >/dev/null
}

main() {
	check_versions
	ensure_clean_git
	preflight_validate
	run_format

	local failures=()
	for p in "${PACKAGES[@]}"; do
		if ! publish_pkg "$p"; then
			failures+=("$p")
		fi
	done

	if [[ ${#failures[@]} -gt 0 ]]; then
			echo ""
			error "Summary of failed packages:" 
			for i in "${!FAIL_PKGS[@]}"; do
				echo -e "  - ${FAIL_PKGS[$i]}: ${FAIL_REASONS[$i]}"
			done
			warn "See detailed logs in: $LOG_DIR" 
			exit 1
	fi

	if [[ $MODE_DRY_RUN -eq 1 ]]; then
		info "Dry-run complete. No packages published."
	else
		info "All requested packages processed."
	fi
}

main "$@"
