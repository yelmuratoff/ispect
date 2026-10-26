# Latest benchmark results

- Commit: `dd196891031b204ae0d46c4ca5e4ae4d72355f1a`
- Generated: `2026-10-26T09:04:11.889563Z`
- OS: `linux`
- Dart: `3.9.2 (stable) (Wed Aug 27 03:49:40 2025 -0700) on "linux_x64"`

| Benchmark | Microseconds per operation |
| --- | ---: |
| logger.metadata-only | 73.95 |
| logger.with-payload | 104.24 |
| logger.with-payload.strict | 105.88 |
| logger.with-payload.redaction-disabled | 102.65 |
| logger.metadata-only.console | 78.54 |
| logger.with-payload.console | 108.71 |
| capture.with-payload | 87.48 |
| export.history.json-lines.100 | 3743.22 |
| export.history.text.100 | 6118.47 |
| logger.history-disabled | 0.01 |
| logger.bounded-history | 74.03 |
| redaction.1kb | 16.50 |
| redaction.10kb | 146.62 |
| redaction.100kb | 1490.01 |
| redaction.export.1kb | 67.50 |
| snapshot.1kb | 7.96 |
| export.json-lines.100 | 3779.26 |
| export.json-lines.1000 | 37578.77 |
| export.json-lines.100.redaction-disabled | 783.34 |
| export.json-lines.1000.redaction-disabled | 8792.49 |
| db.direct-operation | 0.00 |
| db.trace-sync | 154.41 |
| dio.baseline | 47.10 |
| dio.metadata-only | 340.85 |
| dio.body-enabled | 439.47 |
| http.baseline | 6.58 |
| http.metadata-only | 214.16 |
| http.body-enabled | 307.51 |

## Android arm64 release footprint

| Variant | APK bytes |
| --- | ---: |
| Disabled | 16427310 |
| Enabled | 20425006 |
