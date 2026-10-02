---
name: ispect-setup
description: >-
  Set up or troubleshoot ISpect in a Flutter application: guarded startup, diagnostics panel, localization, and navigation observer.
---

# ISpect Flutter setup

Add `ispect` and the Flutter SDK's `flutter_localizations` to the application.
Import `package:ispect/ispect.dart` for the UI and logger exports. Add adapters
only for integrations the app uses.

## Integration

- Start the app with `ISpect.run`. Keep binding initialization and `runApp`
  in its callback or `onInit` so both use the same zone. `onInit` runs only
  when diagnostics are compiled in; put initialization required by public
  builds in the callback.
- Wrap the existing app builder's child with `ISpectBuilder.wrap`. Preserve
  existing wrappers, delegates, supported locales, and observers.
- Keep one stable `ISpectNavigatorObserver` per navigator and reuse it in
  `navigatorObservers` and `ISpectOptions`.
- Pass the same logger to adapters and observers. `ISpect.run` initializes
  `ISpect.logger` before invoking `onInit` and the callback.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

void main() => ISpect.run(() => runApp(const App()));

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _observer = ISpectNavigatorObserver();

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          ...ISpectLocalizations.delegate(),
        ],
        navigatorObservers: ISpectNavigatorObserver.observers(
          observer: _observer,
        ),
        builder: (_, child) => ISpectBuilder.wrap(
          child: child!,
          options: ISpectOptions(observer: _observer),
        ),
        home: const Scaffold(body: Center(child: Text('Application'))),
      );
}
```

## Build and data boundaries

Run internal builds with `flutter run --dart-define=ISPECT_ENABLED=true`.
Omit the define from public release builds. Runtime settings cannot enable
diagnostics when the compile-time flag is absent.

Keep global redaction enabled. Log operation names and counts rather than
credentials or user content. Exports are plain-text diagnostic artifacts;
review them before sharing. Use `ISpectFlutter.init(options: ...)` and pass
that logger to `ISpect.run(logger: ...)` when custom capture budgets or history
are needed. File history is opt-in; the default is in-memory history.

Verify an internal build shows a log and a navigation event in the panel,
then verify a build without the define leaves diagnostics inactive.
