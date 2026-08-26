#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_ROOT="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
TEST_TMP="$(mktemp -d "$TEMP_ROOT/ispect-release-prep-test.XXXXXX")"
FAKE_BIN="$TEST_TMP/bin"
RUNTIME_TMP="$TEST_TMP/runtime"
FAILURES=0

PACKAGES=(
  ispect
  ispect_layout
  ispectify
  ispectify_bloc
  ispectify_db
  ispectify_dio
  ispectify_http
  ispectify_riverpod
  ispectify_ws
)

cleanup() {
  case $TEST_TMP in
    "$TEMP_ROOT"/ispect-release-prep-test.*)
      rm -rf -- "$TEST_TMP"
      ;;
    *)
      echo "refusing to remove unexpected test path: $TEST_TMP" >&2
      return 1
      ;;
  esac
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN" "$RUNTIME_TMP"

cat > "$FAKE_BIN/flutter" <<'FAKE_FLUTTER'
#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
  --version)
    if [[ ${2:-} == "--machine" ]]; then
      printf '{"frameworkVersion": "%s", "channel": "stable", "dartSdkVersion": "3.11.0"}\n' \
        "${FAKE_FLUTTER_VERSION:?FAKE_FLUTTER_VERSION is required}"
    else
      printf 'Flutter %s • channel stable\n' \
        "${FAKE_FLUTTER_VERSION:?FAKE_FLUTTER_VERSION is required}"
    fi
    ;;
  pub)
    if [[ ${2:-} != "get" ]]; then
      echo "fake flutter only supports pub get" >&2
      exit 64
    fi
    version="$(sed -n 's/^VERSION=//p' ../version.config)"
    printf 'fixture-lock: %s\n' "$version" > pubspec.lock
    ;;
  *)
    echo "unexpected fake flutter command: $*" >&2
    exit 64
    ;;
esac
FAKE_FLUTTER

cat > "$FAKE_BIN/dart" <<'FAKE_DART'
#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
  format)
    [[ ${2:-} == "." ]] || {
      echo "fake dart only supports: dart format ." >&2
      exit 64
    }
    ;;
  --version)
    echo "Dart SDK version: 3.11.0 (stable)"
    ;;
  *)
    echo "unexpected fake dart command: $*" >&2
    exit 64
    ;;
esac
FAKE_DART

cat > "$FAKE_BIN/editor" <<'FAKE_EDITOR'
#!/usr/bin/env bash

set -euo pipefail

[[ ${1:-} == "--wait" ]]
[[ ${2:-} == "CHANGELOG.md" ]]
printf '\n### Editor\n\n- Editor arguments were preserved.\n' >> "$2"
exit "${FAKE_EDITOR_EXIT_STATUS:-0}"
FAKE_EDITOR

chmod +x "$FAKE_BIN/flutter" "$FAKE_BIN/dart" "$FAKE_BIN/editor"

die() {
  local message="$1"
  local details_file="${2:-}"

  echo "  $message" >&2
  if [[ -n $details_file && -f $details_file ]]; then
    sed -n '1,160p' "$details_file" >&2
  fi
  exit 1
}

assert_file_contains() {
  local file="$1"
  local expected="$2"

  grep -Fq -- "$expected" "$file" ||
    die "expected $file to contain: $expected"
}

assert_file_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -Fq -- "$unexpected" "$file"; then
    die "expected $file not to contain: $unexpected"
  fi
}

assert_files_equal() {
  local expected="$1"
  local actual="$2"
  local diff_file="$3"

  if ! diff -u "$expected" "$actual" > "$diff_file"; then
    die "files differ: $expected and $actual" "$diff_file"
  fi
}

write_expected_changelog() {
  local path="$1"
  local version="$2"

  cat > "$path" <<EOF
# Changelog

## $version

### Improvements

- Carry these release notes unchanged.
EOF
}

create_fixture() {
  local fixture_name="$1"
  local version="${2:-7.0.0-dev.1}"
  local changelog_version="${3:-$version}"
  local fixture_root="$TEST_TMP/$fixture_name"
  local repo="$fixture_root/repo"
  local package

  mkdir -p \
    "$repo/bash/lib" \
    "$repo/docs/readme/_partials" \
    "$repo/web_logs_viewer"

  cp "$REPO_ROOT/bash/lib/semver.sh" "$repo/bash/lib/semver.sh"
  cp \
    "$REPO_ROOT/bash/release_prep.sh" \
    "$REPO_ROOT/bash/update_versions.sh" \
    "$REPO_ROOT/bash/update_changelog.sh" \
    "$REPO_ROOT/bash/build_readme.sh" \
    "$REPO_ROOT/bash/build_llms.sh" \
    "$REPO_ROOT/bash/check_version_sync.sh" \
    "$REPO_ROOT/bash/check_dependencies.sh" \
    "$repo/bash/"
  chmod +x "$repo/bash/"*.sh

  printf 'VERSION=%s\n' "$version" > "$repo/version.config"
  write_expected_changelog "$repo/CHANGELOG.md" "$changelog_version"

  cat > "$repo/README.md" <<'EOF'
# Stale fixture README

ispect: ^0.0.1
EOF

  cat > "$repo/docs/readme/root.md" <<'EOF'
# Fixture root

Root release {{version}} for {{package}}.
EOF

  cat > "$repo/docs/guide.md" <<'EOF'
# Fixture guide
EOF

  for package in "${PACKAGES[@]}"; do
    mkdir -p "$repo/packages/$package"

    cat > "$repo/packages/$package/pubspec.yaml" <<EOF
name: $package
description: $package fixture
version: 0.0.1
repository: https://example.invalid/ispect
environment:
  sdk: ^3.6.0
EOF

    cat > "$repo/packages/$package/CHANGELOG.md" <<EOF
# Changelog

## 0.0.1

### Improvements

- Stale package notes.
EOF
    printf '# Stale %s README\n' "$package" \
      > "$repo/packages/$package/README.md"
    printf '# %s fixture\n\nPackage {{package}} release {{version}}.\n' \
      "$package" > "$repo/docs/readme/$package.md"
  done

  cat > "$repo/web_logs_viewer/pubspec.yaml" <<'EOF'
name: web_logs_viewer
environment:
  sdk: ^3.6.0
dependencies:
  ispect: ^0.0.1
EOF
  printf 'fixture-lock: 0.0.1\n' > "$repo/web_logs_viewer/pubspec.lock"
  printf 'stale llms index\n' > "$repo/llms.txt"

  echo "$repo"
}

run_release() {
  local repo="$1"
  local flutter_version="$2"
  local output_file="$3"
  shift 3

  (
    cd "$repo"
    PATH="$FAKE_BIN:$PATH" \
      FLUTTER_BIN="$FAKE_BIN/flutter" \
      FAKE_FLUTTER_VERSION="$flutter_version" \
      FAKE_EDITOR_EXIT_STATUS="${RELEASE_EDITOR_EXIT_STATUS:-0}" \
      EDITOR="${RELEASE_EDITOR:-}" \
      TMPDIR="$RUNTIME_TMP" \
      ./bash/release_prep.sh "$@"
  ) > "$output_file" 2>&1
}

test_accepts_newer_flutter() {
  local repo
  local output_file="$TEST_TMP/newer-flutter.log"

  repo="$(create_fixture newer-flutter)"
  if ! run_release "$repo" "3.44.2" "$output_file" --skip-bump; then
    die "release prep rejected fake Flutter 3.44.2" "$output_file"
  fi

  assert_file_contains "$repo/version.config" "VERSION=7.0.0-dev.1"
}

test_rolls_back_every_artifact_after_helper_failure() {
  local repo
  local fixture_root="$TEST_TMP/helper-failure"
  local before="$fixture_root/before"
  local output_file="$fixture_root/release.log"
  local diff_file="$fixture_root/rollback.diff"
  local status

  repo="$(create_fixture helper-failure)"
  cat > "$repo/bash/build_readme.sh" <<'FAILING_HELPER'
#!/usr/bin/env bash

set -euo pipefail

printf 'partially generated root README\n' > README.md
printf 'partially generated package README\n' > packages/ispect/README.md
echo "intentional fixture helper failure" >&2
exit 73
FAILING_HELPER
  chmod +x "$repo/bash/build_readme.sh"
  cp -Rp "$repo" "$before"

  set +e
  run_release "$repo" "3.32.6" "$output_file"
  status=$?
  set -e

  [[ $status -ne 0 ]] ||
    die "release prep unexpectedly succeeded despite helper failure" "$output_file"
  assert_file_contains "$output_file" "intentional fixture helper failure"

  if ! diff -ru "$before" "$repo" > "$diff_file"; then
    die "fixture was not restored exactly after helper failure" "$diff_file"
  fi
}

test_skip_bump_synchronizes_artifacts_without_changing_version() {
  local repo
  local output_file="$TEST_TMP/skip-bump.log"
  local package

  repo="$(create_fixture skip-bump)"
  if ! run_release "$repo" "3.32.6" "$output_file" --skip-bump; then
    die "--skip-bump release prep failed" "$output_file"
  fi

  [[ $(<"$repo/version.config") == "VERSION=7.0.0-dev.1" ]] ||
    die "--skip-bump changed version.config"

  for package in "${PACKAGES[@]}"; do
    assert_file_contains \
      "$repo/packages/$package/pubspec.yaml" \
      "version: 7.0.0-dev.1"
    assert_files_equal \
      "$repo/CHANGELOG.md" \
      "$repo/packages/$package/CHANGELOG.md" \
      "$TEST_TMP/skip-bump-$package.diff"
  done

  assert_file_contains \
    "$repo/README.md" \
    "Root release 7.0.0-dev.1 for ispect."
  assert_file_contains \
    "$repo/packages/ispectify_ws/README.md" \
    "Package ispectify_ws release 7.0.0-dev.1."
  assert_file_contains "$repo/llms.txt" "- Version: 7.0.0-dev.1"
  assert_file_not_contains "$repo/llms.txt" "stale llms index"
}

test_skip_bump_recovers_interrupted_carry_without_empty_stub() {
  local repo
  local output_file="$TEST_TMP/recover-carry.log"
  local expected="$TEST_TMP/recover-carry-expected.md"
  local package

  repo="$(create_fixture recover-carry 7.0.0-dev.2 7.0.0-dev.1)"
  if ! run_release \
    "$repo" \
    "3.32.6" \
    "$output_file" \
    --skip-bump \
    --recover-changelog; then
    die "--skip-bump recovery failed" "$output_file"
  fi

  [[ $(<"$repo/version.config") == "VERSION=7.0.0-dev.2" ]] ||
    die "--skip-bump recovery changed version.config"

  write_expected_changelog "$expected" "7.0.0-dev.2"
  assert_files_equal "$expected" "$repo/CHANGELOG.md" \
    "$TEST_TMP/recover-carry-root.diff"
  assert_file_not_contains "$repo/CHANGELOG.md" "### Added"

  for package in "${PACKAGES[@]}"; do
    assert_files_equal \
      "$expected" \
      "$repo/packages/$package/CHANGELOG.md" \
      "$TEST_TMP/recover-carry-$package.diff"
  done
}

test_skip_bump_preserves_prerelease_history_without_recovery() {
  local repo
  local output_file="$TEST_TMP/preserve-prerelease.log"

  repo="$(create_fixture preserve-prerelease 7.0.0-dev.2 7.0.0-dev.1)"
  if ! run_release "$repo" "3.32.6" "$output_file" --skip-bump; then
    die "--skip-bump failed while preserving prerelease history" "$output_file"
  fi

  assert_file_contains "$repo/CHANGELOG.md" "## 7.0.0-dev.2"
  assert_file_contains "$repo/CHANGELOG.md" "## 7.0.0-dev.1"
  assert_file_contains \
    "$repo/CHANGELOG.md" \
    "- Carry these release notes unchanged."
}

test_carry_bump_advances_the_counter_with_heading_and_notes() {
  local repo
  local output_file="$TEST_TMP/carry-bump.log"
  local expected="$TEST_TMP/carry-bump-expected.md"
  local package

  repo="$(create_fixture carry-bump 7.0.0-dev.1 7.0.0-dev.1)"
  if ! run_release "$repo" "3.32.6" "$output_file" --carry-changelog; then
    die "--carry-changelog release prep failed" "$output_file"
  fi

  [[ $(<"$repo/version.config") == "VERSION=7.0.0-dev.2" ]] ||
    die "prerelease bump did not advance dev.1 -> dev.2"

  write_expected_changelog "$expected" "7.0.0-dev.2"
  assert_files_equal "$expected" "$repo/CHANGELOG.md" \
    "$TEST_TMP/carry-bump-root.diff"

  for package in "${PACKAGES[@]}"; do
    assert_files_equal \
      "$expected" \
      "$repo/packages/$package/CHANGELOG.md" \
      "$TEST_TMP/carry-bump-$package.diff"
  done
}

test_editor_command_preserves_arguments() {
  local repo
  local output_file="$TEST_TMP/editor.log"

  repo="$(create_fixture editor)"
  if ! RELEASE_EDITOR="$FAKE_BIN/editor --wait" \
    run_release "$repo" "3.32.6" "$output_file" --skip-bump --edit; then
    die "--edit failed to preserve editor arguments" "$output_file"
  fi

  assert_file_contains \
    "$repo/CHANGELOG.md" \
    "- Editor arguments were preserved."
  assert_file_contains \
    "$repo/packages/ispect/CHANGELOG.md" \
    "- Editor arguments were preserved."
}

test_editor_failure_preserves_saved_content() {
  local repo
  local output_file="$TEST_TMP/editor-failure.log"
  local backup_path

  repo="$(create_fixture editor-failure)"
  if RELEASE_EDITOR="$FAKE_BIN/editor --wait" \
    RELEASE_EDITOR_EXIT_STATUS=73 \
    run_release "$repo" "3.32.6" "$output_file" --skip-bump --edit; then
    die "--edit unexpectedly succeeded after editor failure" "$output_file"
  fi

  backup_path=$(sed -n \
    's/^\[INFO\] Edited changelog preserved at //p' \
    "$output_file")
  case $backup_path in
    "$RUNTIME_TMP"/ispect-changelog-edit.*)
      ;;
    *)
      die "editor recovery path was not reported safely" "$output_file"
      ;;
  esac
  assert_file_contains \
    "$backup_path" \
    "- Editor arguments were preserved."
  assert_file_not_contains \
    "$repo/CHANGELOG.md" \
    "- Editor arguments were preserved."
}

test_rejects_symlinked_managed_target() {
  local repo
  local output_file="$TEST_TMP/symlink.log"
  local outside_file="$TEST_TMP/outside-readme.md"

  repo="$(create_fixture symlink)"
  printf 'outside sentinel\n' > "$outside_file"
  rm "$repo/README.md"
  ln -s "$outside_file" "$repo/README.md"

  if run_release "$repo" "3.32.6" "$output_file" --skip-bump; then
    die "release prep accepted a symlinked managed target" "$output_file"
  fi

  assert_file_contains \
    "$output_file" \
    "Managed paths cannot contain symlinks: README.md"
  [[ -L $repo/README.md ]] ||
    die "release prep replaced the pre-existing README symlink"
  [[ $(<"$outside_file") == "outside sentinel" ]] ||
    die "release prep wrote through the managed target symlink"
  [[ $(<"$repo/version.config") == "VERSION=7.0.0-dev.1" ]] ||
    die "release prep wrote files before rejecting the symlink"
}

test_missing_snapshot_manifest_retains_recovery_copy() {
  local repo
  local output_file="$TEST_TMP/missing-manifest.log"
  local snapshot_path

  repo="$(create_fixture missing-manifest)"
  cat > "$repo/bash/build_readme.sh" <<'FAILING_HELPER'
#!/usr/bin/env bash

set -euo pipefail

manifest=$(find "${TMPDIR:?}" -type f \
  -path '*/ispect-release-prep.*/existing' -print -quit)
[[ -n $manifest ]]
rm -f -- "$manifest"
echo "intentional missing snapshot manifest" >&2
exit 74
FAILING_HELPER
  chmod +x "$repo/bash/build_readme.sh"

  if run_release "$repo" "3.32.6" "$output_file"; then
    die "release prep succeeded without its snapshot manifest" "$output_file"
  fi

  assert_file_contains \
    "$output_file" \
    "Recovery snapshot manifest is not readable"
  snapshot_path=$(sed -n \
    's/^\[INFO\] Recovery snapshot retained at //p' \
    "$output_file")
  case $snapshot_path in
    "$RUNTIME_TMP"/ispect-release-prep.*)
      ;;
    *)
      die "recovery snapshot path was not retained safely" "$output_file"
      ;;
  esac
  [[ -d $snapshot_path ]] ||
    die "reported recovery snapshot does not exist"
  [[ -f $repo/version.config ]] ||
    die "rollback deleted a pre-existing target after manifest loss"
}

test_conflicting_bump_modes_fail_before_writes() {
  local repo
  local output_file="$TEST_TMP/conflicting-bump.log"

  repo="$(create_fixture conflicting-bump)"
  if run_release "$repo" "3.32.6" "$output_file" patch --bump minor; then
    die "release prep accepted conflicting bump modes" "$output_file"
  fi

  assert_file_contains "$output_file" "Specify the bump kind only once"
  [[ $(<"$repo/version.config") == "VERSION=7.0.0-dev.1" ]] ||
    die "conflicting bump modes wrote version.config"
}

test_recovery_never_renames_stable_history() {
  local repo
  local output_file="$TEST_TMP/stable-recovery.log"

  repo="$(create_fixture stable-recovery 7.0.1 7.0.0)"
  if run_release \
    "$repo" \
    "3.32.6" \
    "$output_file" \
    --skip-bump \
    --recover-changelog; then
    die "release prep renamed stable changelog history" "$output_file"
  fi

  assert_file_contains \
    "$output_file" \
    "--recover-changelog requires the immediately previous prerelease"
  assert_file_contains "$repo/CHANGELOG.md" "## 7.0.0"
  assert_file_not_contains "$repo/CHANGELOG.md" "## 7.0.1"
}

test_recovery_requires_missing_target_section() {
  local repo
  local output_file="$TEST_TMP/existing-recovery-target.log"

  repo="$(create_fixture existing-recovery-target)"
  if run_release \
    "$repo" \
    "3.32.6" \
    "$output_file" \
    --skip-bump \
    --recover-changelog; then
    die "release prep accepted recovery with an existing target" "$output_file"
  fi

  assert_file_contains \
    "$output_file" \
    "--recover-changelog requires the target section to be missing"
  assert_file_contains "$repo/CHANGELOG.md" "## 7.0.0-dev.1"
}

run_test() {
  local name="$1"
  local test_function="$2"
  local status

  printf 'TEST %s\n' "$name"
  set +e
  (
    set -e
    "$test_function"
  )
  status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    echo "PASS $name"
  else
    echo "FAIL $name"
    FAILURES=$((FAILURES + 1))
  fi
}

run_test \
  "release prep accepts Flutter 3.44.2" \
  test_accepts_newer_flutter
run_test \
  "helper failure restores the complete fixture" \
  test_rolls_back_every_artifact_after_helper_failure
run_test \
  "--skip-bump synchronizes changelog, README, and llms.txt" \
  test_skip_bump_synchronizes_artifacts_without_changing_version
run_test \
  "--skip-bump recovers notes from an interrupted carry" \
  test_skip_bump_recovers_interrupted_carry_without_empty_stub
run_test \
  "--skip-bump preserves prerelease history without recovery" \
  test_skip_bump_preserves_prerelease_history_without_recovery
run_test \
  "carry bump advances the prerelease counter with heading and notes" \
  test_carry_bump_advances_the_counter_with_heading_and_notes
run_test \
  "--edit preserves editor command arguments" \
  test_editor_command_preserves_arguments
run_test \
  "editor failures preserve saved changelog content" \
  test_editor_failure_preserves_saved_content
run_test \
  "symlinked managed targets are rejected before writes" \
  test_rejects_symlinked_managed_target
run_test \
  "missing snapshot metadata retains the recovery copy" \
  test_missing_snapshot_manifest_retains_recovery_copy
run_test \
  "conflicting bump modes fail before writes" \
  test_conflicting_bump_modes_fail_before_writes
run_test \
  "recovery never renames stable changelog history" \
  test_recovery_never_renames_stable_history
run_test \
  "recovery requires a missing target section" \
  test_recovery_requires_missing_target_section

if [[ $FAILURES -gt 0 ]]; then
  echo
  echo "$FAILURES release prep regression test(s) failed"
  exit 1
fi

echo
echo "All release prep regression tests passed"
