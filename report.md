# Latest benchmark results

- Commit: `cebf1c1dea8e2cfa7c450a2ce0611b61e191d6a8`
- Generated: `2026-11-13T19:37:18.669136Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 67.25 |
| logger.with-payload | 98.44 |
| logger.with-payload.strict | 102.11 |
| logger.with-payload.redaction-disabled | 97.67 |
| logger.metadata-only.console | 71.99 |
| logger.with-payload.console | 101.19 |
| capture.with-payload | 81.03 |
| export.history.json-lines.100 | 3656.31 |
| export.history.text.100 | 6084.31 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 69.86 |
| redaction.1kb | 16.11 |
| redaction.10kb | 146.17 |
| redaction.100kb | 1476.35 |
| redaction.export.1kb | 67.36 |
| snapshot.1kb | 7.88 |
| export.json-lines.100 | 3748.51 |
| export.json-lines.1000 | 37502.44 |
| export.json-lines.100.redaction-disabled | 778.20 |
| export.json-lines.1000.redaction-disabled | 8523.66 |
| db.direct-operation | 0.00 |
| db.trace-sync | 146.15 |
| dio.baseline | 32.44 |
| dio.metadata-only | 281.51 |
| dio.body-enabled | 347.79 |
| http.baseline | 6.54 |
| http.metadata-only | 201.23 |
| http.body-enabled | 289.36 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20556078 |
