#!/usr/bin/env bash

# Version ordering matches pub_semver's Version.compareTo, the order Pub applies
# when it resolves a constraint: Semantic Versioning 2.0.0 §11 plus Pub's own
# ordering of build metadata.

SEMVER_RE='^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z.-]+))?(\+([0-9A-Za-z.-]+))?$'

semver_is_valid() {
  [[ $1 =~ $SEMVER_RE ]]
}

semver_core() {
  [[ $1 =~ $SEMVER_RE ]] || return 1
  printf '%s.%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
}

semver_prerelease() {
  [[ $1 =~ $SEMVER_RE ]] || return 1
  printf '%s\n' "${BASH_REMATCH[5]}"
}

semver_build() {
  [[ $1 =~ $SEMVER_RE ]] || return 1
  printf '%s\n' "${BASH_REMATCH[7]}"
}

semver_is_numeric_identifier() {
  [[ $1 =~ ^[0-9]+$ ]]
}

# A prerelease counter glued to its label ("dev11") is one alphanumeric
# identifier, so 11 is compared as text and sorts below "dev8".
semver_has_glued_counter() {
  local identifier
  local prerelease

  prerelease=$(semver_prerelease "$1") || return 1
  [[ -n $prerelease ]] || return 1
  while IFS= read -r identifier; do
    if [[ $identifier =~ ^[0-9A-Za-z-]*[A-Za-z-][0-9]+$ ]]; then
      return 0
    fi
  done < <(printf '%s\n' "${prerelease//./$'\n'}")
  return 1
}

semver_compare_identifier() {
  local left="$1"
  local right="$2"
  local LC_ALL=C

  if semver_is_numeric_identifier "$left" && semver_is_numeric_identifier "$right"; then
    if ((10#$left < 10#$right)); then
      printf '%s\n' -1
    elif ((10#$left > 10#$right)); then
      printf '%s\n' 1
    else
      printf '%s\n' 0
    fi
    return 0
  fi
  if semver_is_numeric_identifier "$left"; then
    printf '%s\n' -1
    return 0
  fi
  if semver_is_numeric_identifier "$right"; then
    printf '%s\n' 1
    return 0
  fi
  if [[ $left < $right ]]; then
    printf '%s\n' -1
  elif [[ $left > $right ]]; then
    printf '%s\n' 1
  else
    printf '%s\n' 0
  fi
}

semver_compare_identifier_lists() {
  local left="$1"
  local right="$2"
  local left_ids=()
  local right_ids=()
  local index
  local result

  IFS='.' read -r -a left_ids <<<"$left"
  IFS='.' read -r -a right_ids <<<"$right"

  for ((index = 0; index < ${#left_ids[@]} && index < ${#right_ids[@]}; index++)); do
    result=$(semver_compare_identifier "${left_ids[index]}" "${right_ids[index]}")
    if [[ $result != 0 ]]; then
      printf '%s\n' "$result"
      return 0
    fi
  done

  if ((${#left_ids[@]} < ${#right_ids[@]})); then
    printf '%s\n' -1
  elif ((${#left_ids[@]} > ${#right_ids[@]})); then
    printf '%s\n' 1
  else
    printf '%s\n' 0
  fi
}

# Prints -1, 0, or 1 for left < right, left == right, left > right.
semver_compare() {
  local left="$1"
  local right="$2"
  local left_parts=()
  local right_parts=()
  local index

  semver_is_valid "$left" || {
    echo "[ERR] Invalid semantic version: $left" >&2
    return 1
  }
  semver_is_valid "$right" || {
    echo "[ERR] Invalid semantic version: $right" >&2
    return 1
  }

  IFS='.' read -r -a left_parts <<<"$(semver_core "$left")"
  IFS='.' read -r -a right_parts <<<"$(semver_core "$right")"
  for index in 0 1 2; do
    if ((10#${left_parts[index]} < 10#${right_parts[index]})); then
      printf '%s\n' -1
      return 0
    fi
    if ((10#${left_parts[index]} > 10#${right_parts[index]})); then
      printf '%s\n' 1
      return 0
    fi
  done

  local left_prerelease
  local right_prerelease
  local left_build
  local right_build
  local result

  left_prerelease=$(semver_prerelease "$left")
  right_prerelease=$(semver_prerelease "$right")
  if [[ -n $left_prerelease && -z $right_prerelease ]]; then
    printf '%s\n' -1
    return 0
  fi
  if [[ -z $left_prerelease && -n $right_prerelease ]]; then
    printf '%s\n' 1
    return 0
  fi
  result=$(semver_compare_identifier_lists "$left_prerelease" "$right_prerelease")
  if [[ $result != 0 ]]; then
    printf '%s\n' "$result"
    return 0
  fi

  # Pub orders build metadata instead of ignoring it as Semver §10 prescribes.
  left_build=$(semver_build "$left")
  right_build=$(semver_build "$right")
  if [[ -n $left_build && -z $right_build ]]; then
    printf '%s\n' 1
    return 0
  fi
  if [[ -z $left_build && -n $right_build ]]; then
    printf '%s\n' -1
    return 0
  fi
  semver_compare_identifier_lists "$left_build" "$right_build"
}

semver_is_greater() {
  [[ $(semver_compare "$1" "$2") == 1 ]]
}

semver_max() {
  local highest=""
  local candidate

  for candidate in "$@"; do
    semver_is_valid "$candidate" || continue
    if [[ -z $highest ]] || semver_is_greater "$candidate" "$highest"; then
      highest="$candidate"
    fi
  done
  [[ -n $highest ]] || return 1
  printf '%s\n' "$highest"
}

semver_release_line() {
  local core

  core=$(semver_core "$1") || return 1
  printf '%s\n' "${core%.*}"
}

# The highest candidate sharing the target's MAJOR.MINOR.
semver_max_in_line() {
  local target="$1"
  shift
  local target_line
  local candidate
  local candidates=()

  target_line=$(semver_release_line "$target") || return 1
  for candidate in "$@"; do
    semver_is_valid "$candidate" || continue
    [[ $(semver_release_line "$candidate") == "$target_line" ]] || continue
    candidates+=("$candidate")
  done
  [[ ${#candidates[@]} -gt 0 ]] || return 1
  semver_max "${candidates[@]}"
}

# Advances the prerelease counter so the result always sorts above the input:
# a trailing numeric identifier is incremented, otherwise ".1" is appended.
semver_next_prerelease() {
  local version="$1"
  local core
  local prerelease
  local identifiers=()
  local last_index

  core=$(semver_core "$version") || {
    echo "[ERR] Invalid semantic version: $version" >&2
    return 1
  }
  prerelease=$(semver_prerelease "$version")
  if [[ -z $prerelease ]]; then
    echo "[ERR] Not a prerelease version: $version" >&2
    return 1
  fi

  IFS='.' read -r -a identifiers <<<"$prerelease"
  last_index=$((${#identifiers[@]} - 1))
  if semver_is_numeric_identifier "${identifiers[last_index]}"; then
    identifiers[last_index]=$((10#${identifiers[last_index]} + 1))
  else
    identifiers+=(1)
  fi

  local joined
  printf -v joined '%s.' "${identifiers[@]}"
  printf '%s-%s\n' "$core" "${joined%.}"
}

semver_start_prerelease() {
  local version="$1"
  local label="${2:-dev}"
  local core

  core=$(semver_core "$version") || {
    echo "[ERR] Invalid semantic version: $version" >&2
    return 1
  }
  printf '%s-%s.1\n' "$core" "$label"
}

semver_warn_glued_counter() {
  local version="$1"

  semver_has_glued_counter "$version" || return 0
  echo "[WARN] $version glues its counter to the prerelease label, so Pub compares that counter as text (dev11 sorts below dev8)." >&2
  echo "[WARN] Further bumps stay monotonic by appending a numeric identifier; to sort above an already published sibling the series has to leave this label (rc.1) or the prerelease." >&2
}
