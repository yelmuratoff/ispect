# Latest benchmark results

- Commit: `e34b9416ae4bdd27fd4d36dfe66a0b89ef015590`
- Generated: `2026-11-27T07:53:07.807773Z`
- OS: `linux`
- Dart: `3.13.4 (stable) (Tue Sep 15 01:01:15 2026 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 11.53 |
| logger.with-payload | 46.74 |
| logger.with-payload.strict | 47.08 |
| logger.with-payload.redaction-disabled | 42.22 |
| logger.metadata-only.console | 15.15 |
| logger.with-payload.console | 48.66 |
| capture.with-payload | 28.55 |
| export.history.json-lines.100 | 4473.96 |
| export.history.text.100 | 7345.38 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 11.58 |
| redaction.1kb | 27.12 |
| redaction.10kb | 260.74 |
| redaction.100kb | 2643.50 |
| redaction.export.1kb | 93.00 |
| snapshot.1kb | 10.13 |
| export.json-lines.100 | 5019.40 |
| export.json-lines.1000 | 49569.63 |
| export.json-lines.100.redaction-disabled | 939.04 |
| export.json-lines.1000.redaction-disabled | 10263.63 |
| db.direct-operation | 0.00 |
| db.trace-sync | 135.94 |
| dio.baseline | 31.48 |
| dio.metadata-only | 202.68 |
| dio.body-enabled | 284.79 |
| http.baseline | 9.25 |
| http.metadata-only | 104.12 |
| http.body-enabled | 202.41 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 17248293 |
| Enabled | 21377061 |
