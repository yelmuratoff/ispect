---
name: ispectify-bloc-setup
description: >-
  Set up or tune ispectify_bloc lifecycle diagnostics for BLoC and Cubit in a consumer application, including shared history and safe state capture.
---

# BLoC diagnostics setup

Add `ispectify` and `ispectify_bloc` with existing `bloc` or `flutter_bloc`.
The observer does not change the app's state-management architecture.

## Integration

- Set `Bloc.observer` before constructing BLoCs/Cubits. Pass the app logger;
  otherwise the observer creates a separate logger.
- `Bloc.observer` is a single global slot. Inspect an existing observer before
  replacing it; preserve its behavior with an app-owned delegating observer
  when both are needed.
- With Flutter's `ISpect.run`, install diagnostics in `onInit`. Register
  observers required by public builds outside this diagnostics-only hook.

```dart
import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

void installDiagnostics(ISpectLogger logger) {
  if (!kISpectEnabled) return;
  Bloc.observer = ISpectBlocObserver(
    logger: logger,
    settings: ISpectBlocSettings.compact,
  );
}
```

## Capture policy and verification

Use `--dart-define=ISPECT_ENABLED=true` for internal Flutter runs or
`dart run -DISPECT_ENABLED=true bin/main.dart` for Dart. Omit it from public
builds. Keep redaction enabled. Default `verbose` settings retain bounded,
redacted payloads using balanced capture; `compact` uses strict capture and
coarse value labels. `minimal` reduces lifecycle noise; `silent` disables capture.

Observer `filters` match concrete class names in balanced capture, falling back
to family labels when type lookup fails. Strict/compact capture uses only
`Bloc`, `Cubit`, or `BlocBase`. `filterPredicate` excludes candidates when true;
use explicit app type checks for class exclusions that must work in both modes.
Settings filters such as `eventFilter` include when true. Avoid formatting state
objects in filters to identify their types.

Omit `resourceLimits` to inherit logger policy. Settings `copyWith` accepts
`inheritResourceLimits: true` and `inheritRedactionService: true` to clear
overrides. Restore observers temporarily replaced in consumer tests.

Verify lifecycle/error records in the shared logger, compact summaries without
sensitive state values, and no records without the define.
