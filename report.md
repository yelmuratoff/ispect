# Latest benchmark results

- Commit: `a63280b68e8d94b7e94fd8310b4c1a52c05f9b35`
- Generated: `2026-09-14T17:32:23.490928Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 38.39 |
| logger.with-payload | 71.22 |
| logger.with-payload.strict | 70.13 |
| logger.with-payload.redaction-disabled | 67.75 |
| logger.metadata-only.console | 41.45 |
| logger.with-payload.console | 73.68 |
| capture.with-payload | 58.76 |
| export.history.json-lines.100 | 4313.94 |
| export.history.text.100 | 7081.27 |
| logger.history-disabled | 0.02 |
| logger.bounded-history | 38.37 |
| redaction.1kb | 33.34 |
| redaction.10kb | 187.25 |
| redaction.100kb | 1785.05 |
| redaction.export.1kb | 95.45 |
| snapshot.1kb | 10.11 |
| export.json-lines.100 | 12971.16 |
| export.json-lines.1000 | 130793.06 |
| export.json-lines.100.redaction-disabled | 928.05 |
| export.json-lines.1000.redaction-disabled | 10291.08 |
| db.direct-operation | 0.00 |
| db.trace-sync | 180.37 |
| dio.baseline | 41.87 |
| dio.metadata-only | 284.33 |
| dio.body-enabled | 388.81 |
| http.baseline | 8.09 |
| http.metadata-only | 161.23 |
| http.body-enabled | 172.57 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427254 |
| Enabled | 20162806 |
