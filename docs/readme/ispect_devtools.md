<!-- partial:header -->

`ispect_devtools` adds an ISpect tab to Flutter DevTools. The tab shows the running app's logs, network calls, and traces in the same log viewer as the in-app ISpect panel, so you can keep testing on a device and read diagnostics on the desktop.

- Search, filters, network details, and the JSON viewer from the in-app panel.
- Live: the tab opens with the newest 200 entries the app holds, new logs appear within a second, and a hot restart starts the list over.
- Redacted: the tab reads `ext.ispect.getLogs`, which masks sensitive values the way an export does.

The package has no Dart API and never reaches the app binary. It only carries the extension for DevTools to load.

## Install

```yaml
dependencies:
  ispect: ^{{version}}

dev_dependencies:
  ispect_devtools: ^{{version}}
```

## Use it

1. Run the app in debug or profile mode with `--dart-define=ISPECT_ENABLED=true` and initialize ISpect, for example with `ISpect.run`.
2. Open DevTools and enable the ISpect extension when DevTools asks.
3. Open the ISpect tab.

A build without `ISPECT_ENABLED` registers no ISpect service extensions, and the tab says so instead of showing an empty list. The tab needs `ispect` 8.0.0-dev.2 or newer in the app and asks you to update an older one.

<!-- partial:install_matrix -->

<!-- partial:footer -->
