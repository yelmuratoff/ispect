# Latest benchmark results

- Commit: `3d1cd1b0e31fd12252f6a9b3a5c4e4b529da3b07`
- Generated: `2026-10-14T17:10:49.247842Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 40.03 |
| logger.with-payload | 76.92 |
| logger.with-payload.strict | 78.09 |
| logger.with-payload.redaction-disabled | 73.60 |
| logger.metadata-only.console | 42.93 |
| logger.with-payload.console | 78.55 |
| capture.with-payload | 60.05 |
| export.history.json-lines.100 | 4611.92 |
| export.history.text.100 | 7449.10 |
| logger.history-disabled | 0.02 |
| logger.bounded-history | 40.03 |
| redaction.1kb | 19.76 |
| redaction.10kb | 180.44 |
| redaction.100kb | 1837.16 |
| redaction.export.1kb | 86.71 |
| snapshot.1kb | 10.37 |
| export.json-lines.100 | 4349.29 |
| export.json-lines.1000 | 43392.33 |
| export.json-lines.100.redaction-disabled | 978.47 |
| export.json-lines.1000.redaction-disabled | 10743.60 |
| db.direct-operation | 0.00 |
| db.trace-sync | 135.78 |
| dio.baseline | 33.05 |
| dio.metadata-only | 286.45 |
| dio.body-enabled | 348.71 |
| http.baseline | 8.33 |
| http.metadata-only | 162.52 |
| http.body-enabled | 260.59 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20359470 |
