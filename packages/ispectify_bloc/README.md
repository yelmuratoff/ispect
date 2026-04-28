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


**ispectify_bloc** plugs the [`bloc`](https://pub.dev/packages/bloc) / [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). It forwards every event, state change, transition, and error through a single `BlocObserver` so you can see the entire state-management timeline in the log viewer.

- Events, transitions, errors, create / close lifecycle hooks.
- Per-type filtering — mute specific `Bloc`/`Cubit` classes without touching their code.
- Zero-config: set `Bloc.observer` and you're done.

## Install

```yaml
dependencies:
  flutter_bloc: ^8.0.0
  ispectify: ^5.0.0-dev37
  ispectify_bloc: ^5.0.0-dev37
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

## The ISpect toolkit

ISpect is a modular monorepo. Install only what your project needs — each package works independently.

| Package | What it does |
| --- | --- |
| [`ispect`](https://pub.dev/packages/ispect) | Flutter UI — debug panel, log viewer, navigation observer, inspector integration |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout) | Visual layout inspector — sizes, constraints, decorations, compare mode, color picker |
| [`ispectify`](https://pub.dev/packages/ispectify) | Pure-Dart logging core — typed log entries, filtering, tracing, observers |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio) | Dio HTTP interceptor with automatic redaction |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http) | `http` package interceptor with automatic redaction |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws) | WebSocket traffic capture with automatic redaction |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db) | Database operation tracing (SQL, ORM, KV stores) |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc) | BLoC event / state / transition observer |


## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/yelmuratoff/ispect/blob/main/CONTRIBUTING.md) for guidelines, and open issues or pull requests at the [ISpect repository](https://github.com/yelmuratoff/ispect).

## License

MIT — see [LICENSE](https://github.com/yelmuratoff/ispect/blob/main/LICENSE).

---

<div align="center">
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" alt="Contributors" />
  </a>
</div>
