# ispect_devtools_extension

The Flutter web app behind the ISpect tab in Flutter DevTools. It reads the
debugged app's logs through the `ext.ispect.getLogs` service extension and
shows them in ISpect's own log viewer.

It is not published itself. `ispect_tool publish` builds it into
`packages/ispect_devtools/extension/devtools/build` before it publishes
`ispect_devtools`, and that folder stays out of git.

## Build

From the repository root, with Flutter 3.47 or newer on `PATH`:

```sh
dart run tool/bin/ispect_tool.dart devtools-extension
```

The build passes `--dart-define=ISPECT_ENABLED=true`: the tab shows logs
through an ISpect logger, which the compile gate otherwise switches off.

## Test

```sh
flutter test --dart-define=ISPECT_ENABLED=true
```

To try the tab against a running app, see
[DevTools extensions](https://docs.flutter.dev/tools/devtools/extensions).
