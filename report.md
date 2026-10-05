# Latest benchmark results

- Commit: `9509bc26dedda7c9fb82275a560161d102d41e18`
- Generated: `2026-10-05T10:34:35.986067Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 60.68 |
| logger.with-payload | 81.99 |
| logger.with-payload.strict | 86.10 |
| logger.with-payload.redaction-disabled | 82.78 |
| logger.metadata-only.console | 63.24 |
| logger.with-payload.console | 86.93 |
| capture.with-payload | 74.81 |
| export.history.json-lines.100 | 2589.88 |
| export.history.text.100 | 4167.01 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 59.51 |
| redaction.1kb | 21.06 |
| redaction.10kb | 115.67 |
| redaction.100kb | 1048.16 |
| redaction.export.1kb | 58.37 |
| snapshot.1kb | 5.82 |
| export.json-lines.100 | 8509.57 |
| export.json-lines.1000 | 87973.13 |
| export.json-lines.100.redaction-disabled | 498.87 |
| export.json-lines.1000.redaction-disabled | 5726.55 |
| db.direct-operation | 0.00 |
| db.trace-sync | 146.09 |
| dio.baseline | 21.86 |
| dio.metadata-only | 251.47 |
| dio.body-enabled | 312.93 |
| http.baseline | 4.65 |
| http.metadata-only | 171.76 |
| http.body-enabled | 185.90 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20162862 |
