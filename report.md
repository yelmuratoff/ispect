# Latest benchmark results

- Commit: `7a332a418556b6a543014823b3d79f3d6bf39416`
- Generated: `2026-08-31T09:54:41.149578Z`
- OS: `linux`
- Dart: `3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 71.97 |
| logger.with-payload | 72.31 |
| logger.history-disabled | 71.89 |
| logger.bounded-history | 72.25 |
| redaction.1kb | 371.21 |
| redaction.10kb | 3668.04 |
| redaction.100kb | 36805.14 |
| export.json-lines.100 | 5066.27 |
| export.json-lines.1000 | 50885.50 |
| db.direct-operation | 0.01 |
| db.trace-sync | 156.41 |
| dio.baseline | 38.99 |
| dio.metadata-only | 435.02 |
| dio.body-enabled | 456.99 |
| http.baseline | 9.00 |
| http.metadata-only | 216.56 |
| http.body-enabled | 217.04 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 8046367 |
| Enabled | 9320659 |
