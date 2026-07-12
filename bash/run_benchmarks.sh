#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${root_dir}/build/benchmarks"
binary="${output_dir}/ispectify_benchmarks"
db_binary="${output_dir}/ispectify_db_benchmarks"

mkdir -p "${output_dir}"
pushd "${root_dir}/packages/ispectify" >/dev/null
dart pub get
dart compile exe benchmark/ispectify_benchmarks.dart -o "${binary}"
popd >/dev/null

"${binary}" --output "${output_dir}/ispectify.json"

pushd "${root_dir}/packages/ispectify_db" >/dev/null
dart pub get --no-example
dart compile exe benchmark/db_benchmarks.dart -o "${db_binary}"
popd >/dev/null

"${db_binary}" --output "${output_dir}/ispectify_db.json"

commit="${GITHUB_SHA:-$(git -C "${root_dir}" rev-parse HEAD)}"
pushd "${root_dir}/packages/ispectify" >/dev/null
dart run benchmark/generate_benchmark_report.dart \
  --input "${output_dir}/ispectify.json" \
  --additional-input "${output_dir}/ispectify_db.json" \
  --output "${output_dir}/published" \
  --commit "${commit}"
popd >/dev/null
