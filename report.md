# Latest benchmark results

- Commit: `3326c8c30422f6896f35087682236f6867465e47`
- Generated: `2026-11-07T09:13:00.117960Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 34.56 |
| logger.with-payload | 68.95 |
| logger.with-payload.strict | 70.40 |
| logger.with-payload.redaction-disabled | 66.66 |
| logger.metadata-only.console | 37.62 |
| logger.with-payload.console | 72.57 |
| capture.with-payload | 53.84 |
| export.history.json-lines.100 | 4525.76 |
| export.history.text.100 | 7490.27 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 34.82 |
| redaction.1kb | 21.90 |
| redaction.10kb | 198.37 |
| redaction.100kb | 2022.91 |
| redaction.export.1kb | 88.62 |
| snapshot.1kb | 10.48 |
| export.json-lines.100 | 4274.78 |
| export.json-lines.1000 | 42355.72 |
| export.json-lines.100.redaction-disabled | 919.41 |
| export.json-lines.1000.redaction-disabled | 10371.18 |
| db.direct-operation | 0.00 |
| db.trace-sync | 129.44 |
| dio.baseline | 47.37 |
| dio.metadata-only | 242.80 |
| dio.body-enabled | 315.02 |
| http.baseline | 8.81 |
| http.metadata-only | 151.88 |
| http.body-enabled | 243.31 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20556078 |
