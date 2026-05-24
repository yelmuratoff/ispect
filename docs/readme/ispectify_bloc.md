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
  onInit: () {
    Bloc.observer = ISpectBlocObserver(logger: ISpect.logger);
  },
);
```

The observer emits logs under the `bloc-event`, `bloc-transition`, `bloc-state`, `bloc-create`, `bloc-close`, `bloc-done`, and `bloc-error` log-type keys, each with a dedicated icon, palette entry, and localized description in the log viewer. Filter them in the debug panel or through `ISpectSettingsState.disabledLogTypes`.

## Settings

`ISpectBlocSettings` controls which lifecycle events are captured and whether raw event/state payloads are written to trace meta. Payload capture is off by default — runtime types are emitted instead, so it is safe to leave the observer enabled in shared environments.

```dart
const settings = ISpectBlocSettings(
  printEvents: true,
  printTransitions: true,
  printChanges: true,
  printCreations: true,
  printClosings: true,
  printCompletions: true,
  printErrors: true,
  printEventFullData: false, // raw event payloads off by default
  printStateFullData: false, // raw state payloads off by default
  enableRedaction: true,     // route meta values through RedactionService when set
);
```

### Presets

```dart
// Logs disabled entirely.
ISpectBlocObserver(settings: ISpectBlocSettings.silent);

// Skip per-change / per-completion noise — keeps creations, transitions, errors.
ISpectBlocObserver(settings: ISpectBlocSettings.minimal);

// Full state payloads on transitions and changes.
ISpectBlocObserver(settings: ISpectBlocSettings.verbose);
```

### Filtering noisy blocs

```dart
ISpectBlocObserver(
  // Drop everything for blocs whose runtime type matches one of these patterns.
  filters: [RegExp(r'AnalyticsBloc'), 'MetricsCubit'],
  settings: ISpectBlocSettings(
    // Or skip individual events / transitions / changes by inspecting them.
    eventFilter: (bloc, event) => event is! HeartbeatEvent,
  ),
);
```

<!-- partial:install_matrix -->

<!-- partial:footer -->
