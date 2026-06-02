<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_bloc.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify_bloc">
      <img src="https://img.shields.io/pub/v/ispectify_bloc?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&labelColor=0360a9&color=2ab7f6" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=for-the-badge&logo=github&labelColor=0360a9&color=2ab7f6" alt="GitHub stars">
    </a>
    <a href="https://codecov.io/gh/yelmuratoff/ispect">
      <img src="https://img.shields.io/codecov/c/github/yelmuratoff/ispect?style=for-the-badge&logo=codecov&labelColor=0360a9&color=2ab7f6" alt="Coverage">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispectify_bloc/score">
      <img src="https://img.shields.io/pub/likes/ispectify_bloc?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_bloc/score">
      <img src="https://img.shields.io/pub/points/ispectify_bloc?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify_bloc">
      <img src="https://img.shields.io/pub/dm/ispectify_bloc?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


`ispectify_bloc` plugs the [`bloc`](https://pub.dev/packages/bloc) and [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). One `BlocObserver` forwards every event, state change, transition, and error through the log pipeline, so the whole state-management timeline shows up in the log viewer.

- Events, transitions, errors, and create/close lifecycle hooks.
- Per-type filtering. Mute specific `Bloc` or `Cubit` classes without touching their code.
- Zero configuration. Set `Bloc.observer` and the rest is done.

## Install

```yaml
dependencies:
  flutter_bloc: ^8.0.0
  ispectify: ^5.2.0-dev.14
  ispectify_bloc: ^5.2.0-dev.14
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

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI: debug panel, log viewer, navigation observer, inspector integration. |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core: typed log entries, filtering, tracing, observers. |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction. |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction. |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | WebSocket traffic capture with automatic redaction. |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing for SQL, ORMs, and KV stores. |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event, state, transition, and error observer. |
| [`ispectify_riverpod`](https://pub.dev/packages/ispectify_riverpod) | Riverpod provider add, update, dispose, and failure observer. |


## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT. See [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
