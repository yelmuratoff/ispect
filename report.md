# Latest benchmark results

- Commit: `7a332a418556b6a543014823b3d79f3d6bf39416`
- Generated: `2026-09-07T08:26:15.127821Z`
- OS: `linux`
- Dart: `3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 73.31 |
| logger.with-payload | 72.42 |
| logger.history-disabled | 71.88 |
| logger.bounded-history | 73.66 |
| redaction.1kb | 374.78 |
| redaction.10kb | 3668.63 |
| redaction.100kb | 36918.41 |
| export.json-lines.100 | 5110.06 |
| export.json-lines.1000 | 50712.23 |
| db.direct-operation | 0.01 |
| db.trace-sync | 157.59 |
| dio.baseline | 37.52 |
| dio.metadata-only | 433.97 |
| dio.body-enabled | 445.73 |
| http.baseline | 8.90 |
| http.metadata-only | 215.25 |
| http.body-enabled | 216.03 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 8046365 |
| Enabled | 9320653 |
