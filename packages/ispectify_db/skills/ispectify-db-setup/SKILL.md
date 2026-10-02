---
name: ispectify-db-setup
description: >-
  Instrument SQL, ORM, or key-value storage calls with ispectify_db timing, safe result projections, and redaction in a consumer application.
---

# Database diagnostics setup

Add `ispectify` and `ispectify_db` alongside the existing storage driver.
This is passive tracing, not a database client or driver factory.

## Integration

- Wrap the actual async operation with `logger.dbTrace<T>`; use
  `dbTraceSync<T>` for synchronous drivers. Share the app logger.
- Keep `source` and `operation` stable for grouping. Supply parameterized SQL
  as `statement` with arguments separately, not interpolated user data.
- Project results to counts or safe summaries with `projectResult`, not whole
  rows, credentials, or user content.
- Preserve results and failures; traces do not replace transactions or retries.

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

Future<List<Map<String, Object?>>> traceItems(
  ISpectLogger logger,
  Future<List<Map<String, Object?>>> Function() query,
) =>
    logger.dbTrace<List<Map<String, Object?>>>(
      source: 'item_store',
      operation: 'query',
      statement: 'SELECT id FROM items',
      table: 'items',
      run: query,
      projectResult: (rows) => {'rows': rows.length},
      config: const ISpectDbConfig(
        redact: true,
        captureMode: DiagnosticCaptureMode.strict,
        slowThreshold: Duration(milliseconds: 400),
      ),
    );
```

## Capture policy and verification

Use `--dart-define=ISPECT_ENABLED=true` for internal Flutter runs or
`dart run -DISPECT_ENABLED=true bin/main.dart` for Dart. Omit it from public
builds; storage calls must still execute when tracing is disabled.

Keep `ISpectDbConfig.redact` true. Omit `redactKeys` to follow the global
service: a supplied set is a local replacement, not an additive extension.
Extend the global service's keys for app-specific fields. Strict capture
avoids app-defined formatting; balanced is the default. Omit `resourceLimits`
to inherit logger policy, or clear overrides with
`copyWith(inheritResourceLimits: true)`.

Verify success and a thrown error using a fake storage call. Check unchanged
results, propagating errors, summaries without rows, and masked captured args.
Without the define, verify calls still execute with no diagnostic entries.
