#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FAILURES=0

source "$REPO_ROOT/bash/lib/semver.sh"

die() {
  echo "  $1" >&2
  exit 1
}

assert_compare() {
  local left="$1"
  local expected="$2"
  local right="$3"
  local actual

  actual=$(semver_compare "$left" "$right")
  [[ $actual == "$expected" ]] ||
    die "expected semver_compare $left $right to be $expected, got $actual"
}

assert_next_prerelease() {
  local version="$1"
  local expected="$2"
  local actual

  actual=$(semver_next_prerelease "$version")
  [[ $actual == "$expected" ]] ||
    die "expected semver_next_prerelease $version to be $expected, got $actual"
  [[ $(semver_compare "$actual" "$version") == 1 ]] ||
    die "$actual does not sort above $version"
}

test_core_precedence() {
  assert_compare 7.0.0 -1 7.0.1
  assert_compare 7.0.1 -1 7.1.0
  assert_compare 7.1.0 -1 8.0.0
  assert_compare 7.0.0 0 7.0.0
  assert_compare 7.10.0 1 7.9.0
}

test_prerelease_sorts_below_its_release() {
  assert_compare 7.0.0-dev.1 -1 7.0.0
  assert_compare 7.0.0 1 7.0.0-rc.1
}

test_numeric_identifiers_compare_numerically() {
  assert_compare 7.0.0-dev.9 -1 7.0.0-dev.10
  assert_compare 7.0.0-dev.10 -1 7.0.0-dev.11
  assert_compare 7.0.0-dev.2 -1 7.0.0-dev.10
}

# The published 7.0.0-dev8..dev11 series: a counter glued to the label is one
# alphanumeric identifier, so Pub compares it as text and dev11 resolves below
# dev8. Pinning the order here keeps the scripts from producing that shape again.
test_glued_counters_compare_as_text() {
  assert_compare 7.0.0-dev11 -1 7.0.0-dev8
  assert_compare 7.0.0-dev10 -1 7.0.0-dev9
  assert_compare 7.0.0-dev.11 -1 7.0.0-dev8
  assert_compare 7.0.0-dev9.1 1 7.0.0-dev9
  assert_compare 7.0.0-rc.1 1 7.0.0-dev9
  [[ $(semver_max 7.0.0-dev8 7.0.0-dev9 7.0.0-dev10 7.0.0-dev11) == 7.0.0-dev9 ]] ||
    die "semver_max disagrees with Pub on the published dev series"
}

test_numeric_identifiers_sort_below_alphanumeric() {
  assert_compare 7.0.0-1 -1 7.0.0-a
  assert_compare 7.0.0-alpha -1 7.0.0-alpha.1
  assert_compare 7.0.0-alpha.1 -1 7.0.0-alpha.beta
  assert_compare 7.0.0-beta.2 -1 7.0.0-beta.11
}

test_build_metadata_sorts_above_no_build() {
  assert_compare 7.0.0 -1 7.0.0+meta
  assert_compare 7.0.0-dev.1+build1 -1 7.0.0-dev.1+build2
}

test_next_prerelease_always_rises() {
  assert_next_prerelease 7.0.0-dev.1 7.0.0-dev.2
  assert_next_prerelease 7.0.0-dev.9 7.0.0-dev.10
  assert_next_prerelease 7.0.0-rc 7.0.0-rc.1
  assert_next_prerelease 7.0.0-dev9 7.0.0-dev9.1
  assert_next_prerelease 7.0.0-dev11 7.0.0-rc.1
  assert_next_prerelease 7.0.0-dev01 7.0.0-dev01.1

  semver_next_prerelease 7.0.0 2>/dev/null &&
    die "semver_next_prerelease accepted a stable version"
  return 0
}

test_start_prerelease_uses_dot_form() {
  [[ $(semver_start_prerelease 7.1.0 dev) == 7.1.0-dev.1 ]] ||
    die "semver_start_prerelease did not produce the dot form"
  [[ $(semver_compare 7.1.0-dev.1 7.0.0) == 1 ]] ||
    die "a fresh prerelease must sort above the previous release"
}

test_release_line_peak_ignores_other_lines() {
  local published=(6.1.6 6.1.7 7.0.0-dev8 7.0.0-dev9 7.0.0-dev10 7.0.0-dev11 7.1.0)

  [[ $(semver_max_in_line 7.0.0-rc.1 "${published[@]}") == 7.0.0-dev9 ]] ||
    die "the 7.0 peak should be 7.0.0-dev9, the version Pub ranks highest"
  [[ $(semver_max_in_line 6.1.8 "${published[@]}") == 6.1.7 ]] ||
    die "a 6.1 backport should be judged against 6.1.7, not against 7.1.0"
  [[ $(semver_max_in_line 7.1.1 "${published[@]}") == 7.1.0 ]] ||
    die "the 7.1 peak should be 7.1.0"

  semver_max_in_line 8.0.0-dev.1 "${published[@]}" 2>/dev/null &&
    die "a line with nothing published should report no peak"
  [[ $(semver_release_line 7.0.0-dev11) == 7.0 ]] ||
    die "a prerelease belongs to the line of its core"
  return 0
}

test_validation_rejects_malformed_versions() {
  semver_is_valid 7.0 && die "accepted 7.0"
  semver_is_valid 7.0.0- && die "accepted a trailing hyphen"
  semver_is_valid v7.0.0 && die "accepted a v prefix"
  semver_is_valid 7.0.0-dev.1 || die "rejected a valid prerelease"
  semver_has_glued_counter 7.0.0-dev11 || die "missed the glued counter in dev11"
  semver_has_glued_counter 7.0.0-dev.11 && die "flagged the dot form as glued"
  return 0
}

run_test() {
  local name="$1"
  local test_function="$2"
  local status

  echo "[TEST] $name"
  set +e
  (
    set -e
    "$test_function"
  )
  status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    echo "[PASS] $name"
  else
    echo "[FAIL] $name" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

run_test \
  "core versions compare numerically" \
  test_core_precedence
run_test \
  "a prerelease sorts below its release" \
  test_prerelease_sorts_below_its_release
run_test \
  "numeric identifiers compare numerically" \
  test_numeric_identifiers_compare_numerically
run_test \
  "counters glued to a label compare as text" \
  test_glued_counters_compare_as_text
run_test \
  "numeric identifiers sort below alphanumeric ones" \
  test_numeric_identifiers_sort_below_alphanumeric
run_test \
  "build metadata sorts above no build" \
  test_build_metadata_sorts_above_no_build
run_test \
  "the next prerelease always sorts above its input" \
  test_next_prerelease_always_rises
run_test \
  "a fresh prerelease uses the dot form" \
  test_start_prerelease_uses_dot_form
run_test \
  "the release-line peak ignores other lines" \
  test_release_line_peak_ignores_other_lines
run_test \
  "validation rejects malformed versions" \
  test_validation_rejects_malformed_versions

if [[ $FAILURES -ne 0 ]]; then
  echo "[FAIL] $FAILURES semver test(s) failed" >&2
  exit 1
fi

echo "[PASS] semver tests"
