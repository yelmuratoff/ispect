#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_ROOT="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
TEST_TMP="$(mktemp -d "$TEMP_ROOT/ispect-pub-api-test.XXXXXX")"
FAKE_BIN="$TEST_TMP/bin"
FAILURES=0

cleanup() {
  case $TEST_TMP in
    "$TEMP_ROOT"/ispect-pub-api-test.*)
      rm -rf -- "$TEST_TMP"
      ;;
    *)
      echo "refusing to remove unexpected test path: $TEST_TMP" >&2
      return 1
      ;;
  esac
}
trap cleanup EXIT

source "$REPO_ROOT/bash/lib/semver.sh"
source "$REPO_ROOT/bash/lib/pub_api.sh"

mkdir -p "$FAKE_BIN"

# Stands in for curl: writes the fixture named by FAKE_PUB_BODY to the path
# given by --output and echoes FAKE_PUB_STATUS, the way --write-out does.
cat > "$FAKE_BIN/curl" <<'FAKE_CURL'
#!/usr/bin/env bash

set -euo pipefail

output=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --output)
      output="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ ${FAKE_PUB_EXIT:-0} -ne 0 ]]; then
  exit "${FAKE_PUB_EXIT}"
fi
if [[ -n $output ]]; then
  if [[ -n ${FAKE_PUB_BODY:-} ]]; then
    cat "$FAKE_PUB_BODY" > "$output"
  else
    : > "$output"
  fi
fi
printf '%s' "${FAKE_PUB_STATUS:-200}"
FAKE_CURL
chmod +x "$FAKE_BIN/curl"

PATH="$FAKE_BIN:$PATH"

die() {
  echo "  $1" >&2
  exit 1
}

write_fixture() {
  local path="$1"

  cat > "$path" <<'EOF'
{"name":"ispect","latest":{"version":"6.1.7","pubspec":{"name":"ispect","version":"6.1.7",
"environment":{"sdk":">=3.6.0 <4.0.0"},"dependencies":{"ispectify":"^6.1.7","dio":"^5.9.2"}}},
"versions":[
{"version":"6.1.7","pubspec":{"name":"ispect","version":"6.1.7"},"archive_url":"https://x/6.1.7"},
{"version":"7.0.0-dev8","pubspec":{"name":"ispect","version":"7.0.0-dev8"},"archive_url":"https://x/d8"},
{"version":"7.0.0-dev9","pubspec":{"name":"ispect","version":"7.0.0-dev9"},"archive_url":"https://x/d9"},
{"version":"7.0.0-dev10","pubspec":{"name":"ispect","version":"7.0.0-dev10"},"archive_url":"https://x/d10"},
{"version":"7.0.0-dev11","pubspec":{"name":"ispect","version":"7.0.0-dev11"},"archive_url":"https://x/d11"}
]}
EOF
}

test_extracts_every_published_version_once() {
  local fixture="$TEST_TMP/ispect.json"
  local listing

  write_fixture "$fixture"
  listing=$(FAKE_PUB_BODY="$fixture" FAKE_PUB_STATUS=200 pub_api_published_versions ispect)

  [[ $(printf '%s\n' "$listing" | wc -l | tr -d ' ') == 5 ]] ||
    die "expected 5 distinct versions, got: $(printf '%s' "$listing" | tr '\n' ' ')"
  for expected in 6.1.7 7.0.0-dev8 7.0.0-dev9 7.0.0-dev10 7.0.0-dev11; do
    printf '%s\n' "$listing" | grep -Fqx "$expected" ||
      die "missing $expected from the listing"
  done
}

test_peak_of_the_line_matches_pub_resolution() {
  local fixture="$TEST_TMP/ispect.json"
  local versions=()
  local version

  write_fixture "$fixture"
  while IFS= read -r version; do
    versions+=("$version")
  done < <(FAKE_PUB_BODY="$fixture" FAKE_PUB_STATUS=200 pub_api_published_versions ispect)

  [[ $(semver_max_in_line 7.0.0-rc.1 "${versions[@]}") == 7.0.0-dev9 ]] ||
    die "the 7.0 line peak should be 7.0.0-dev9"
  [[ $(semver_max_in_line 6.1.8 "${versions[@]}") == 6.1.7 ]] ||
    die "the 6.1 line peak should be 6.1.7"
  semver_max_in_line 8.0.0-dev.1 "${versions[@]}" 2>/dev/null &&
    die "an unpublished line should report no peak"
  return 0
}

test_unpublished_package_reports_no_versions() {
  local listing
  local status=0

  listing=$(FAKE_PUB_STATUS=404 pub_api_published_versions brand_new) || status=$?
  [[ $status -eq 0 ]] || die "a 404 should succeed, got exit $status"
  [[ -z $listing ]] || die "a 404 should report no versions, got: $listing"
}

test_unanswered_request_fails_loudly() {
  local status=0

  FAKE_PUB_STATUS=503 pub_api_published_versions ispect >/dev/null 2>&1 || status=$?
  [[ $status -eq 1 ]] || die "a 503 should fail, got exit $status"

  status=0
  FAKE_PUB_EXIT=6 pub_api_published_versions ispect >/dev/null 2>&1 || status=$?
  [[ $status -eq 1 ]] || die "an unreachable host should fail, got exit $status"
}

test_non_version_json_noise_is_discarded() {
  local fixture="$TEST_TMP/noisy.json"
  local listing
  local version
  local versions=()

  cat > "$fixture" <<'EOF'
{"name":"x","versions":[
{"version":"1.0.0","pubspec":{"version":"1.0.0","description":"the \"version\" of record"}},
{"version" : "not-a-version"},
{"version":"1.0.1"}
]}
EOF

  listing=$(FAKE_PUB_BODY="$fixture" FAKE_PUB_STATUS=200 pub_api_published_versions x)
  printf '%s\n' "$listing" | grep -Fqx "not-a-version" &&
    die "a malformed version string reached the listing"

  while IFS= read -r version; do
    [[ -n $version ]] && versions+=("$version")
  done <<< "$listing"

  [[ ${#versions[@]} -eq 2 ]] ||
    die "expected 2 valid versions, got: ${versions[*]}"
  [[ $(semver_max_in_line 1.0.2 "${versions[@]}") == 1.0.1 ]] ||
    die "expected the 1.0 peak to be 1.0.1, got: ${versions[*]}"
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
  "every published version is extracted once" \
  test_extracts_every_published_version_once
run_test \
  "the release-line peak matches how Pub ranks the series" \
  test_peak_of_the_line_matches_pub_resolution
run_test \
  "an unpublished package reports no versions" \
  test_unpublished_package_reports_no_versions
run_test \
  "an unanswered request fails loudly" \
  test_unanswered_request_fails_loudly
run_test \
  "non-version JSON noise is discarded" \
  test_non_version_json_noise_is_discarded

if [[ $FAILURES -ne 0 ]]; then
  echo "[FAIL] $FAILURES pub_api test(s) failed" >&2
  exit 1
fi

echo "[PASS] pub_api tests"
