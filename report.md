# Latest benchmark results

- Commit: `a775b2bc58500fc8bbefbde2f41f8550074853f7`
- Generated: `2026-07-21T04:52:19.771220Z`
- OS: `linux`
- Dart: `3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 71.93 |
| logger.with-payload | 71.10 |
| logger.history-disabled | 69.71 |
| logger.bounded-history | 69.75 |
| redaction.1kb | 391.02 |
| redaction.10kb | 3679.58 |
| redaction.100kb | 37069.15 |
| export.json-lines.100 | 4966.43 |
| export.json-lines.1000 | 49693.20 |
| db.direct-operation | 0.01 |
| db.trace-sync | 152.38 |
| dio.baseline | 37.93 |
| dio.metadata-only | 414.12 |
| dio.body-enabled | 414.88 |
| http.baseline | 8.37 |
| http.metadata-only | 213.57 |
| http.body-enabled | 215.14 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 8046366 |
| Enabled | 9320013 |
