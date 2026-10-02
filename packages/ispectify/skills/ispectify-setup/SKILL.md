---
name: ispectify-setup
description: >-
  Set up or troubleshoot ispectify structured logging and operation traces in a Dart application without the Flutter diagnostics UI.
---

# ispectify logging setup

Add `ispectify` and import `package:ispectify/ispectify.dart`. The pure Dart
core does not require Flutter; add `ispect` only for the Flutter panel.

## Integration

- Create one application-owned `ISpectLogger` and share it with adapters;
  independent loggers separate their histories.
- Configure `ISpectLoggerOptions` for history, console, capture mode, resource
  limits, and processing policy. At least one consumer (history, console,
  stream, or observer) is needed for capture.
- Use `traceAsync`, `traceSync`, or `traceStream` for duration and outcomes.
  Choose an exported category or an `ISpectTraceCategory` with stable IDs.
  Project results to safe summaries and preserve original failures.
- Dispose an owned logger with `await logger.dispose()` at lifecycle end.

```dart
import 'package:ispectify/ispectify.dart';

Future<void> main() async {
  final logger = ISpectLogger(
    options: ISpectLoggerOptions(
      useConsoleLogs: false,
      maxHistoryItems: 1000,
      captureMode: DiagnosticCaptureMode.strict,
      resourceLimits: DiagnosticResourceLimits.constrained,
    ),
  );
  try {
    logger.info('Refresh started');
    await logger.traceAsync<List<int>>(
      category: storageCategory,
      source: 'item_repository',
      operation: 'refresh',
      run: () async => [1, 2, 3],
      projectResult: (items) => {'count': items.length},
    );
  } finally {
    await logger.dispose();
  }
}
```

## Build and data boundaries

Enable internal Dart runs with `dart run -DISPECT_ENABLED=true bin/main.dart`;
for Flutter use `flutter run --dart-define=ISPECT_ENABLED=true`. Omit the define
from public builds. `options.enabled` cannot replace `kISpectEnabled`.

Keep `ISpectRedaction.enabled` on. Extend sensitive keys with
`ISpectRedaction.configure(service: RedactionService(additionalSensitiveKeys:
{'app-secret'}))`. Avoid PII in manual messages. Balanced capture may invoke
guarded `toJson()`/`toString()`; strict avoids app-defined formatters. Observers
and exports receive redacted data by default; external forwarding needs an
explicit sink.

Verify history gets entries in an enabled run and stays empty without the
define. Verify traced failures still reach the caller.
