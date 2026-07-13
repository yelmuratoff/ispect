# Performance Scope

ISpect runs inside internal builds. Runtime cost should be evaluated in that context, not against production traffic.

## Disabled builds

When `ISPECT_ENABLED` is omitted, every ISpect entry point is inactive. The disabled path is a compile-time constant, so release builds let Dart's tree-shaker drop the inactive toolkit code.

## Enabled internal builds

When the toolkit is on, overhead depends on what you capture:

- Metadata-only logs are the lightest mode.
- Request and response body capture is heavier than metadata, proportional to payload size.
- Database tracing cost scales with trace volume and result projection. Counts and IDs are cheap. Dumping full row contents is not.
- High-volume BLoC and event streams need filters or sampling.
- Long sessions need bounded history and exports limited to the relevant window.

## Controls

- Start with the debug panel and metadata-only diagnostics.
- Turn payload and body capture on for targeted debugging only.
- Filter or sample noisy categories.
- Prefer a result projection over a full database row.
- Keep the history bounded for long QA sessions.

## Benchmarks

CI publishes the latest generated report to the
[`benchmark-data`](https://github.com/yelmuratoff/ispect/blob/benchmark-data/report.md)
branch. It is generated from benchmark artifacts and must not be edited by
hand. Measurements are comparison data for the recorded commit and machine,
not universal performance claims.

The current report covers AOT pure-Dart hot paths and Android arm64 release
footprint: logging, history, redaction, JSON Lines export, database tracing,
and Dio/http adapter overhead. Startup and high-volume frame measurements
remain device-run scenarios; publish them only with the device model, refresh
rate, OS, commit, and generated report.

## Reproducing measurements

Use Flutter `3.32.6` and record the machine, operating system, device, commit
SHA, and date with every result. Warm up a device before comparing runs; never
compare results from different machines as though they were a regression.

### Pure Dart hot paths

The `ispectify` benchmark covers metadata-only and payload logging, disabled
and bounded history, redaction of 1, 10, and 100 KB payloads, and JSON Lines
exports of 100 and 1,000 entries. The same run measures `ispectify_db`
`dbTraceSync` against a direct in-memory operation, plus `dio.*` and `http.*`
request batches against fixed in-memory transports. The adapter suites compare
the baseline client, metadata-only diagnostics, and body-enabled diagnostics.
All pure Dart cases compile to AOT before running so that JIT warm-up does not
distort the result.

```bash
./bash/run_benchmarks.sh
```

The command writes `build/benchmarks/ispectify.json` and the generated report.
Its values are microseconds per operation and are intended for comparisons
made under the same conditions, not as universal performance claims.

### Release footprint

```bash
./bash/measure_release_size.sh
```

This builds the `ispect` example twice: once with `ISPECT_ENABLED` omitted and
once enabled. APKs and `--analyze-size` reports are saved to
`build/benchmarks/release-size/`. Compare the two analysis JSON files in the
DevTools App Size tool; do not present the raw APK as a store download-size
estimate. If benchmark inputs are missing, the script first runs the pure Dart
benchmark suite so that the published report remains complete.

### Startup and frame timing

Run profile mode on the same physical Android device for each variant:

```bash
cd packages/ispect/example
flutter run --profile --trace-startup
flutter run --profile --trace-startup --dart-define=ISPECT_ENABLED=true
```

Record `timeToFirstFrameMicros` from each trace. The high-volume scenario
collects both `FrameTiming.buildDuration` and `FrameTiming.rasterDuration`;
build time alone cannot expose raster-thread jank.

The fixed high-volume scenario is an integration test. It runs only in profile
mode, renders the same 2,000 synthetic events with filters disabled and enabled,
and places build/raster timing summaries plus missed-frame counts in the
integration-test report data:

```bash
cd packages/ispect/example
flutter test integration_test/high_volume_profile_test.dart --profile -d <device-id> \
  --dart-define=ISPECT_ENABLED=true
```

Record the device model, refresh rate, OS, commit, and the generated report
alongside any published comparison. The scenario is a measurement harness, not
a CI regression threshold.
