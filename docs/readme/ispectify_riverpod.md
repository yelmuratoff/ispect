<!-- partial:header -->

`ispectify_riverpod` plugs the [`riverpod`](https://pub.dev/packages/riverpod) and [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). One `ProviderObserver` forwards every provider add, update, dispose, and failure through the log pipeline, so the whole provider lifecycle shows up in the log viewer.

- Adds, updates, disposes, and failures with provider values captured by default.
- Per-provider filtering. Mute noisy providers without touching their code.
- Zero configuration. Hand the observer to `ProviderScope` (or `ProviderContainer`) and you are done.

## Install

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  ispectify: ^{{version}}
  ispectify_riverpod: ^{{version}}
```

## Quick start

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';

ISpect.run(
  () => runApp(
    ProviderScope(
      observers: [ISpectRiverpodObserver(logger: ISpect.logger)],
      child: const MyApp(),
    ),
  ),
);
```

The observer emits logs under the `riverpod-add`, `riverpod-update`, `riverpod-dispose`, and `riverpod-fail` log-type keys, each with a dedicated icon, palette entry, and localized description in the log viewer. Filter them in the debug panel or through `ISpectSettingsState.disabledLogTypes`.

## Settings

`ISpectRiverpodSettings` controls which lifecycle events are captured and whether raw provider values are written to trace meta. `printValues` defaults to `true` — ISpect is compile-time gated by `ISPECT_ENABLED` and never ships to production, so verbose value capture is the more useful trade.

```dart
const settings = ISpectRiverpodSettings(
  printAdds: true,
  printUpdates: true,
  printDisposes: true,
  printFails: true,
  printValues: true,        // raw values in meta — default
  enableRedaction: true,    // route values through RedactionService when set
);
```

### Presets

```dart
// Logs disabled entirely.
ISpectRiverpodObserver(settings: ISpectRiverpodSettings.silent);

// Lifecycle creation, disposal, and failures — updates are muted.
ISpectRiverpodObserver(settings: ISpectRiverpodSettings.minimal);

// Reduces values to runtime types only. Use when provider state may carry PII
// and you still want lifecycle visibility.
ISpectRiverpodObserver(settings: ISpectRiverpodSettings.compact);
```

### Filtering noisy providers

```dart
ISpectRiverpodObserver(
  // Drop everything for providers whose name matches one of these patterns.
  filters: [RegExp(r'cache'), 'metrics'],
  settings: ISpectRiverpodSettings(
    // Or skip individual updates by inspecting the values.
    updateFilter: (provider, previous, next) =>
        previous != next,
  ),
);
```

<!-- partial:redaction -->

Supply a custom `RedactionService` to mask sensitive provider state:

```dart
ISpectRiverpodObserver(
  logger: ISpect.logger,
  settings: ISpectRiverpodSettings(
    redactor: RedactionService(
      sensitiveKeys: {...defaultSensitiveKeys, 'access-token'},
    ),
  ),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
