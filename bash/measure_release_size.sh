#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
example_dir="${root_dir}/packages/ispect/example"
output_dir="${root_dir}/build/benchmarks/release-size"
benchmark_input_dir="${root_dir}/build/benchmarks"

required_benchmark_inputs=(
  "${benchmark_input_dir}/ispectify.json"
  "${benchmark_input_dir}/ispectify_db.json"
  "${benchmark_input_dir}/ispectify_dio.json"
  "${benchmark_input_dir}/ispectify_http.json"
)

for benchmark_input in "${required_benchmark_inputs[@]}"; do
  if [[ ! -f "${benchmark_input}" ]]; then
    "${root_dir}/bash/run_benchmarks.sh"
    break
  fi
done

mkdir -p "${output_dir}"
pushd "${example_dir}" >/dev/null

if [[ ! -d android ]]; then
  flutter create --platforms=android --org com.example .
fi

flutter pub get

build_variant() {
  local name="$1"
  shift
  local analysis_input_dir="${output_dir}/${name}-analysis-input"
  local analysis_marker="${output_dir}/.${name}-analysis-start"
  local analysis_report

  rm -f "${output_dir}/${name}.apk" "${output_dir}/${name}-analysis.json"
  rm -rf "${analysis_input_dir}"
  mkdir -p "${analysis_input_dir}"
  touch "${analysis_marker}"
  flutter clean
  flutter build apk \
    --release \
    --target-platform android-arm64 \
    --analyze-size \
    --code-size-directory "${analysis_input_dir}" \
    --no-tree-shake-icons \
    "$@"
  cp build/app/outputs/flutter-apk/app-release.apk "${output_dir}/${name}.apk"
  analysis_report="$(
    find "${HOME}/.flutter-devtools" \
      -maxdepth 1 \
      -type f \
      -name 'apk-code-size-analysis*.json' \
      -newer "${analysis_marker}" \
      -print |
      tail -n 1
  )"
  rm -f "${analysis_marker}"

  if [[ -z "${analysis_report}" ]]; then
    echo "Flutter did not produce an APK size-analysis report for ${name}." >&2
    return 1
  fi
  cp "${analysis_report}" "${output_dir}/${name}-analysis.json"
}

build_variant disabled
build_variant enabled --dart-define=ISPECT_ENABLED=true
popd >/dev/null

shasum -a 256 "${output_dir}"/*.apk

commit="${GITHUB_SHA:-$(git -C "${root_dir}" rev-parse HEAD)}"
report_args=(
  --input "${root_dir}/build/benchmarks/ispectify.json"
  --output "${root_dir}/build/benchmarks/published"
  --commit "${commit}"
  --disabled-apk "${output_dir}/disabled.apk"
  --enabled-apk "${output_dir}/enabled.apk"
)

for additional_input in \
  "${root_dir}/build/benchmarks/ispectify_db.json" \
  "${root_dir}/build/benchmarks/ispectify_dio.json" \
  "${root_dir}/build/benchmarks/ispectify_http.json"; do
  if [[ -f "${additional_input}" ]]; then
    report_args+=(--additional-input "${additional_input}")
  fi
done

pushd "${root_dir}/packages/ispectify" >/dev/null
dart run benchmark/generate_benchmark_report.dart \
  "${report_args[@]}"
popd >/dev/null
