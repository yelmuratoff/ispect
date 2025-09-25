# ispectify_db example

A tiny console example showing passive DB logging with `ispectify_db`.

It demonstrates patterns for:
- Drift-like SQL (query/update)
- Hive-like key-value (get)
- SharedPreferences-like key-value (write)
- Transaction markers with correlated `transactionId`

Run

```bash
cd packages/ispectify_db/example
dart pub get
dart run lib/main.dart
```

Notes
- This example uses fake operations (delays) to simulate DB calls.
- Replace the closures with your real driver calls; the logging API stays the same.
