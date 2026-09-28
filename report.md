# Latest benchmark results

- Commit: `9509bc26dedda7c9fb82275a560161d102d41e18`
- Generated: `2026-09-28T09:55:43.747681Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 76.25 |
| logger.with-payload | 113.56 |
| logger.with-payload.strict | 113.88 |
| logger.with-payload.redaction-disabled | 113.06 |
| logger.metadata-only.console | 79.25 |
| logger.with-payload.console | 115.99 |
| capture.with-payload | 96.23 |
| export.history.json-lines.100 | 4718.26 |
| export.history.text.100 | 7875.80 |
| logger.history-disabled | 0.02 |
| logger.bounded-history | 76.25 |
| redaction.1kb | 44.95 |
| redaction.10kb | 260.18 |
| redaction.100kb | 2429.24 |
| redaction.export.1kb | 112.55 |
| snapshot.1kb | 10.93 |
| export.json-lines.100 | 17515.98 |
| export.json-lines.1000 | 175537.67 |
| export.json-lines.100.redaction-disabled | 931.67 |
| export.json-lines.1000.redaction-disabled | 10396.95 |
| db.direct-operation | 0.01 |
| db.trace-sync | 265.66 |
| dio.baseline | 40.16 |
| dio.metadata-only | 448.17 |
| dio.body-enabled | 568.47 |
| http.baseline | 8.63 |
| http.metadata-only | 271.20 |
| http.body-enabled | 288.39 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20162862 |
