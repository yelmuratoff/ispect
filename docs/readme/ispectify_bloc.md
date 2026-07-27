<!-- partial:header -->

`ispectify_bloc` plugs the [`bloc`](https://pub.dev/packages/bloc) and [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). One `BlocObserver` forwards every event, state change, transition, and error through the log pipeline, so the whole state-management timeline shows up in the log viewer.

- Events, transitions, errors, and create/close lifecycle hooks.
- Family and typed-predicate filtering. Mute BLoCs without formatting caller-owned objects.
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

`ISpectBlocSettings` controls which lifecycle events are captured and whether raw event/state payloads are written to trace meta. Payload capture is off by default. BLoCs use the coarse family labels `Bloc`, `Cubit`, or `BlocBase`; common event/state shapes use structural labels such as `String`, `int`, `List`, or `Map`, and other caller-owned objects use `Object`. These labels do not invoke application `runtimeType` or `toString()` methods.

```dart
const settings = ISpectBlocSettings(
  printEvents: true,
  printTransitions: true,
  printChanges: true,
  printCreations: true,
  printClosings: true,
  printCompletions: true,
  printErrors: true,
  printEventFullData: false, // coarse structural label — default
  printStateFullData: false, // coarse structural label — default
  enableRedaction: true,     // route meta values through RedactionService when set
);
```

### Presets

```dart
// Logs disabled entirely.
ISpectBlocObserver(settings: ISpectBlocSettings.silent);

// Skip per-change / per-completion noise — keeps creations, transitions, errors.
ISpectBlocObserver(settings: ISpectBlocSettings.minimal);

// Explicit local-development payload capture; redaction remains enabled.
ISpectBlocObserver(
  settings: ISpectBlocSettings.development,
);
```

### Filtering noisy blocs

```dart
ISpectBlocObserver(
  // Pattern filters see only Bloc, Cubit, or BlocBase.
  filters: ['Cubit'],

  // Use explicit type checks when an exact application class must be muted.
  filterPredicate: (candidate) =>
      candidate is AnalyticsBloc || candidate is MetricsCubit,

  settings: ISpectBlocSettings(
    // Or skip individual events / transitions / changes by inspecting them.
    eventFilter: (bloc, event) => event is! HeartbeatEvent,
  ),
);
```

<!-- partial:redaction -->

<!-- partial:install_matrix -->

<!-- partial:footer -->
