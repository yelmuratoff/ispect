<!--
  GENERATED FILE - do not edit by hand.
  Source:     docs/readme/ispect_devtools.md
  Regenerate: dart run tool/bin/ispect_tool.dart readme
-->

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">

  <p>
    <a href="https://pub.dev/packages/ispect_devtools">
      <img src="https://img.shields.io/pub/v/ispect_devtools?include_prereleases&style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="pub version">
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
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/production_safety.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/production_safety.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Production%20Safety&labelColor=0360a9" alt="Production Safety workflow">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/test.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/test.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Test%20%26%20Analyze&labelColor=0360a9" alt="Test and Analyze workflow">
    </a>
    <a href="https://github.com/yelmuratoff/ispect/actions/workflows/deploy-web-logs-viewer.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/ispect/deploy-web-logs-viewer.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Web%20Demo%20Deploy&labelColor=0360a9" alt="Deploy Web Logs Viewer workflow">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/ispect_devtools/score">
      <img src="https://img.shields.io/pub/likes/ispect_devtools?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect_devtools/score">
      <img src="https://img.shields.io/pub/points/ispect_devtools?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/ispect_devtools">
      <img src="https://img.shields.io/pub/dm/ispect_devtools?style=for-the-badge&logo=flutter&labelColor=0360a9&color=2ab7f6" alt="Pub downloads">
    </a>
  </p>
</div>

`ispect_devtools` adds an ISpect tab to Flutter DevTools. The tab shows the running app's logs, network calls, and traces in the same log viewer as the in-app ISpect panel, so you can keep testing on a device and read diagnostics on the desktop.

- Search, filters, network details, and the JSON viewer from the in-app panel.
- Live: the tab opens with the newest 200 entries the app holds, new logs appear within a second, and a hot restart starts the list over.
- Redacted: the tab reads `ext.ispect.getLogs`, which masks sensitive values the way an export does.

The package has no Dart API and never reaches the app binary. It only carries the extension for DevTools to load.

## Install

```yaml
dependencies:
  ispect: ^8.0.0-dev.2

dev_dependencies:
  ispect_devtools: ^8.0.0-dev.2
```

## Use it

1. Run the app in debug or profile mode with `--dart-define=ISPECT_ENABLED=true` and initialize ISpect, for example with `ISpect.run`.
2. Open DevTools and enable the ISpect extension when DevTools asks.
3. Open the ISpect tab.

A build without `ISPECT_ENABLED` registers no ISpect service extensions, and the tab says so instead of showing an empty list. The tab needs `ispect` 8.0.0-dev.2 or newer in the app and asks you to update an older one.

## The ISpect toolkit

ISpect is a modular monorepo. Pick the packages your project needs. Each one works on its own.

| Package                                                             | What it does                                                                                    |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`ispect`](https://pub.dev/packages/ispect)                         | Flutter UI: debug panel, log viewer, navigation observer, inspector integration.                |
| [`ispect_devtools`](https://pub.dev/packages/ispect_devtools)       | Flutter DevTools tab with the running app's logs in ISpect's log viewer.                        |
| [`ispect_layout`](https://pub.dev/packages/ispect_layout)           | Visual layout inspector with sizes, constraints, decorations, compare mode, and a color picker. |
| [`ispectify`](https://pub.dev/packages/ispectify)                   | Pure-Dart logging core: typed log entries, filtering, tracing, observers.                       |
| [`ispectify_dio`](https://pub.dev/packages/ispectify_dio)           | Dio HTTP interceptor with automatic redaction.                                                  |
| [`ispectify_http`](https://pub.dev/packages/ispectify_http)         | `http` package interceptor with automatic redaction.                                            |
| [`ispectify_ws`](https://pub.dev/packages/ispectify_ws)             | Provider-agnostic WebSocket capture (any client) with automatic redaction.                      |
| [`ispectify_db`](https://pub.dev/packages/ispectify_db)             | Database operation tracing for SQL, ORMs, and KV stores.                                        |
| [`ispectify_bloc`](https://pub.dev/packages/ispectify_bloc)         | BLoC event, state, transition, and error observer.                                              |
| [`ispectify_riverpod`](https://pub.dev/packages/ispectify_riverpod) | Riverpod provider add, update, dispose, and failure observer.                                   |

## AI package skills

Each ISpect package bundles a focused setup skill for coding agents. From your
application directory, after resolving dependencies, install skills for your
direct dependencies with:

```bash
dart run skills@ get
```

For a single package, use `dart run skills@ get -p <package_name>` (for example,
`-p ispectify_dio`). The skills cover public integration APIs, compile-time
gating, and safe capture settings. `ispect` and `ispectify` also ship
`ispect-read-logs` and `ispectify-read-logs`, which let an agent read redacted
logs from a running debug build through the `ext.ispect` VM service extensions.
Run the same `get` command after upgrading to refresh installed skills. See
[Dart package skills](https://dart.dev/ai/package-skills) for installation and
update options. These consumer skills are separate from
the repository's contributor skills.

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
