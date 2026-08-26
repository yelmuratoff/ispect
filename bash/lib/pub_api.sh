#!/usr/bin/env bash

# Reads the version history a package host already published.
# https://pub.dev/help/api documents /api/packages/<name>.

PUB_API_HOST="${PUB_HOSTED_URL:-https://pub.dev}"
PUB_API_TIMEOUT_SECONDS="${PUB_API_TIMEOUT_SECONDS:-30}"

# Prints every published version of the package, one per line, unordered.
# An unpublished package (404) succeeds with no output; any other failure
# returns 1 so callers can refuse to proceed on an unanswered question.
pub_api_published_versions() {
  local package="$1"
  local body
  local status_code
  local version

  command -v curl >/dev/null 2>&1 || {
    echo "[ERR] curl is required to read $PUB_API_HOST" >&2
    return 1
  }

  body=$(mktemp "${TMPDIR:-/tmp}/pub-api.XXXXXX") || return 1
  status_code=$(
    curl \
      --silent \
      --show-error \
      --location \
      --max-time "$PUB_API_TIMEOUT_SECONDS" \
      --header 'Accept: application/vnd.pub.v2+json' \
      --output "$body" \
      --write-out '%{http_code}' \
      "$PUB_API_HOST/api/packages/$package" 2>/dev/null
  ) || status_code=000

  case $status_code in
    200) ;;
    404)
      rm -f -- "$body"
      return 0
      ;;
    *)
      rm -f -- "$body"
      echo "[ERR] $PUB_API_HOST/api/packages/$package answered $status_code" >&2
      return 1
      ;;
  esac

  while IFS= read -r version; do
    semver_is_valid "$version" && printf '%s\n' "$version"
  done < <(
    grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$body" |
      sed -e 's/.*"\([^"]*\)"$/\1/' |
      sort -u
  )
  rm -f -- "$body"
}
