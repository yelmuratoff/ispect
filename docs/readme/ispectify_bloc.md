<!-- partial:header -->

**ispectify_bloc** plugs the [`bloc`](https://pub.dev/packages/bloc) / [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). It forwards every event, state change, transition, and error through a single `BlocObserver` so you can see the entire state-management timeline in the log viewer.

- Events, transitions, errors, create / close lifecycle hooks.
- Per-type filtering — mute specific `Bloc`/`Cubit` classes without touching their code.
- Zero-config: set `Bloc.observer` and you're done.

## Install

```yaml
dependencies:
  flutter_bloc: ^8.0.0
  ispectify: ^{{version}}
  ispectify_bloc: ^{{version}}
```

## Quick start

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

ISpect.run(
  () => runApp(const MyApp()),
  logger: logger,
  onInit: () {
    Bloc.observer = ISpectBlocObserver(logger: logger);
  },
);
```

The observer emits logs under the `bloc-event`, `bloc-transition`, `bloc-change`, `bloc-error`, and `bloc-create`/`bloc-close` log-type keys — filter them in the debug panel or via `ISpectSettingsState.disabledLogTypes`.

<!-- partial:install_matrix -->

<!-- partial:footer -->
