---
name: ispectify-riverpod-setup
description: >-
  Set up or tune ispectify_riverpod provider lifecycle diagnostics in a Riverpod consumer application, with filtering and redacted value capture.
---

# Riverpod diagnostics setup

Add `ispectify` and `ispectify_riverpod` with compatible `riverpod` or
`flutter_riverpod`. This package uses Riverpod 2's observer API; check installed
constraints before suggesting Riverpod 3 observer signatures.

## Integration

- Add `ISpectRiverpodObserver(logger: logger)` to existing `ProviderScope` or
  `ProviderContainer` observers before providers are created. Preserve other
  observers and overrides.
- Share the app logger. Flutter's `ISpect.run` initializes `ISpect.logger`
  before its callback, where `ProviderScope` can be constructed.
- Dispose owned containers; diagnostics does not own them or replace error
  handling.

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:riverpod/riverpod.dart';

ProviderContainer createContainer(ISpectLogger logger) => ProviderContainer(
      observers: [
        if (kISpectEnabled)
          ISpectRiverpodObserver(
            logger: logger,
            settings: ISpectRiverpodSettings.compact,
          ),
      ],
    );
```

## Capture policy and verification

Use `--dart-define=ISPECT_ENABLED=true` for internal Flutter runs or
`dart run -DISPECT_ENABLED=true bin/main.dart` for Dart. Omit it from public
builds. Keep redaction enabled. Default `verbose` retains bounded, redacted
values using balanced capture; `compact` uses strict capture and coarse labels.
`minimal` omits updates; `silent` disables capture.

Name providers for stable name-based filtering. Observer `filters` exclude
matching names. Unnamed providers use concrete type names in balanced capture
and the fallback label `Provider` in strict/compact capture or if type lookup
fails. `filterPredicate` sees the resolved name and excludes when true. Settings
`providerFilter` and `updateFilter` include when true; use them for provider
identity or comparisons instead of formatting objects.

Omit `resourceLimits` to inherit logger policy. Settings
`copyWith(inheritResourceLimits: true, inheritRedactionService: true)` restores
global policies after local overrides.

Verify add/update/dispose/failure records, named-provider exclusions, safe
compact summaries, and no capture without the define.
