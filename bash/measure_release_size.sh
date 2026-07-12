#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
example_dir="${root_dir}/packages/ispect/example"
output_dir="${root_dir}/build/benchmarks/release-size"

mkdir -p "${output_dir}"
pushd "${example_dir}" >/dev/null

if [[ ! -d android ]]; then
  flutter create --platforms=android --org com.example .
fi

flutter pub get

build_variant() {
  local name="$1"
  shift
  rm -f "${output_dir}/${name}.apk" "${output_dir}/${name}-analysis.json"
  flutter build apk \
    --release \
    --target-platform android-arm64 \
    --analyze-size \
    --no-tree-shake-icons \
    "$@"
  cp build/app/outputs/flutter-apk/app-release.apk "${output_dir}/${name}.apk"
  find build -name '*code-size-analysis*.json' -type f -print0 |
    xargs -0 ls -t |
    head -n 1 |
    xargs -I {} cp {} "${output_dir}/${name}-analysis.json"
}

build_variant disabled
build_variant enabled --dart-define=ISPECT_ENABLED=true
popd >/dev/null

shasum -a 256 "${output_dir}"/*.apk

commit="${GITHUB_SHA:-$(git -C "${root_dir}" rev-parse HEAD)}"
pushd "${root_dir}/packages/ispectify" >/dev/null
dart run benchmark/generate_benchmark_report.dart \
  --input "${root_dir}/build/benchmarks/ispectify.json" \
  --output "${root_dir}/build/benchmarks/published" \
  --commit "${commit}" \
  --disabled-apk "${output_dir}/disabled.apk" \
  --enabled-apk "${output_dir}/enabled.apk"
popd >/dev/null
