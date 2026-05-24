<!-- partial:header -->

`ispectify_riverpod` plugs the [`riverpod`](https://pub.dev/packages/riverpod) and [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). One `ProviderObserver` forwards every provider add, update, dispose, and failure through the log pipeline, so the whole provider lifecycle shows up in the log viewer.

- Adds, updates, disposes, and failures with values redacted by default.
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
      observers: [ISpectRiverpodObserver(logger: logger)],
      child: const MyApp(),
    ),
  ),
  logger: logger,
);
```

The observer emits logs under the `riverpod-add`, `riverpod-update`, `riverpod-dispose`, and `riverpod-fail` log-type keys. Filter them in the debug panel or through `ISpectSettingsState.disabledLogTypes`.

<!-- partial:install_matrix -->

<!-- partial:footer -->
