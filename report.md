# Latest benchmark results

- Commit: `b7341cec11f8f1b6b9dac553d0fea6e6009c14a6`
- Generated: `2026-09-21T09:04:53.597039Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 73.37 |
| logger.with-payload | 103.36 |
| logger.with-payload.strict | 105.63 |
| logger.with-payload.redaction-disabled | 102.78 |
| logger.metadata-only.console | 77.30 |
| logger.with-payload.console | 107.41 |
| capture.with-payload | 88.23 |
| export.history.json-lines.100 | 3529.57 |
| export.history.text.100 | 5921.96 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 73.74 |
| redaction.1kb | 26.15 |
| redaction.10kb | 158.69 |
| redaction.100kb | 1442.65 |
| redaction.export.1kb | 74.54 |
| snapshot.1kb | 8.00 |
| export.json-lines.100 | 10303.83 |
| export.json-lines.1000 | 103759.20 |
| export.json-lines.100.redaction-disabled | 737.66 |
| export.json-lines.1000.redaction-disabled | 7954.30 |
| db.direct-operation | 0.00 |
| db.trace-sync | 185.59 |
| dio.baseline | 30.96 |
| dio.metadata-only | 342.84 |
| dio.body-enabled | 438.32 |
| http.baseline | 6.64 |
| http.metadata-only | 221.44 |
| http.body-enabled | 236.48 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427254 |
| Enabled | 20162806 |
