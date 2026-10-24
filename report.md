# Latest benchmark results

- Commit: `dd196891031b204ae0d46c4ca5e4ae4d72355f1a`
- Generated: `2026-10-24T08:34:50.391714Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 74.01 |
| logger.with-payload | 105.41 |
| logger.with-payload.strict | 108.12 |
| logger.with-payload.redaction-disabled | 104.62 |
| logger.metadata-only.console | 77.21 |
| logger.with-payload.console | 107.82 |
| capture.with-payload | 88.25 |
| export.history.json-lines.100 | 3780.84 |
| export.history.text.100 | 6250.38 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 73.93 |
| redaction.1kb | 15.75 |
| redaction.10kb | 144.78 |
| redaction.100kb | 1478.87 |
| redaction.export.1kb | 67.95 |
| snapshot.1kb | 7.81 |
| export.json-lines.100 | 3772.61 |
| export.json-lines.1000 | 38841.46 |
| export.json-lines.100.redaction-disabled | 780.85 |
| export.json-lines.1000.redaction-disabled | 8840.87 |
| db.direct-operation | 0.00 |
| db.trace-sync | 151.85 |
| dio.baseline | 30.67 |
| dio.metadata-only | 304.15 |
| dio.body-enabled | 386.36 |
| http.baseline | 6.47 |
| http.metadata-only | 215.42 |
| http.body-enabled | 308.52 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20425006 |
