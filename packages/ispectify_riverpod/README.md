<!--
  GENERATED FILE — do not edit by hand.
  Source:     docs/readme/ispectify_riverpod.md
  Regenerate: ./bash/build_readme.sh
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispectify_riverpod">
      <img src="https://img.shields.io/pub/v/ispectify_riverpod?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
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
    <a href="https://pub.dev/packages/ispectify_riverpod/score">
      <img src="https://img.shields.io/pub/likes/ispectify_riverpod?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_riverpod/score">
      <img src="https://img.shields.io/pub/points/ispectify_riverpod?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispectify_riverpod">
      <img src="https://img.shields.io/pub/dm/ispectify_riverpod?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>


`ispectify_riverpod` plugs the [`riverpod`](https://pub.dev/packages/riverpod) and [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) ecosystem into the [ISpect toolkit](#the-ispect-toolkit). One `ProviderObserver` forwards every provider add, update, dispose, and failure through the log pipeline, so the whole provider lifecycle shows up in the log viewer.

- Adds, updates, disposes, and failures with values redacted by default.
- Per-provider filtering. Mute noisy providers without touching their code.
- Zero configuration. Hand the observer to `ProviderScope` (or `ProviderContainer`) and you are done.

## Install

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  ispectify: ^5.2.0-dev.7
  ispectify_riverpod: ^5.2.0-dev.7
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
