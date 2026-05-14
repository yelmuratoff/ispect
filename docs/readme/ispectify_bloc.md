<!-- partial:header -->

`ispectify_bloc` plugs the [`bloc`](https://pub.dev/packages/bloc) and [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). One `BlocObserver` forwards every event, state change, transition, and error through the log pipeline, so the whole state-management timeline shows up in the log viewer.

- Events, transitions, errors, and create/close lifecycle hooks.
- Per-type filtering. Mute specific `Bloc` or `Cubit` classes without touching their code.
- Zero configuration. Set `Bloc.observer` and the rest is done.

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

The observer emits logs under the `bloc-event`, `bloc-transition`, `bloc-change`, `bloc-error`, `bloc-create`, and `bloc-close` log-type keys. Filter them in the debug panel or through `ISpectSettingsState.disabledLogTypes`.

<!-- partial:install_matrix -->

<!-- partial:footer -->
