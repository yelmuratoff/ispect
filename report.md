# Latest benchmark results

- Commit: `a2f5d21bef733bdfa7c74854361dd9512e76a7b6`
- Generated: `2026-11-16T11:28:04.533850Z`
- OS: `linux`
- Dart: `3.13.4 (stable) (Tue Sep 15 01:01:15 2026 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 9.20 |
| logger.with-payload | 34.56 |
| logger.with-payload.strict | 34.78 |
| logger.with-payload.redaction-disabled | 31.61 |
| logger.metadata-only.console | 12.16 |
| logger.with-payload.console | 36.50 |
| capture.with-payload | 22.21 |
| export.history.json-lines.100 | 3123.29 |
| export.history.text.100 | 5263.46 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 9.11 |
| redaction.1kb | 18.48 |
| redaction.10kb | 170.83 |
| redaction.100kb | 1741.17 |
| redaction.export.1kb | 69.78 |
| snapshot.1kb | 8.15 |
| export.json-lines.100 | 3957.02 |
| export.json-lines.1000 | 38742.11 |
| export.json-lines.100.redaction-disabled | 623.04 |
| export.json-lines.1000.redaction-disabled | 7065.91 |
| db.direct-operation | 0.00 |
| db.trace-sync | 103.14 |
| dio.baseline | 19.88 |
| dio.metadata-only | 147.72 |
| dio.body-enabled | 192.49 |
| http.baseline | 7.18 |
| http.metadata-only | 76.43 |
| http.body-enabled | 148.85 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 17231461 |
| Enabled | 21360229 |
