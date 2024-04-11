<div align="center">
<p align="center">
    <a href="https://github.com/K1yoshiSho/ispect" align="center">
        <img src="https://github.com/K1yoshiSho/packages_assets/blob/main/assets/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> Wrapper around Inspector, Talker and etc 🚀 </h2>

<p align="center">
This package was not created as something unique, it is a set of good tools from the expanse of pub.dev and my kind of implementation of all this for future projects, I decided to share it, maybe it will be useful to someone. I will improve, add along with the growth of the main packages used, and maybe add new functions. 😊


   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/K1yoshiSho/ispect.git">star the repo</a> to support the project! </span>
</p>

<p align="center">
  <a href="https://pub.dev/packages/ispect"><img src="https://img.shields.io/pub/v/ispect.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/K1yoshiSho/ispect"><img src="https://hits.dwyl.com/K1yoshiSho/ispect.svg?style=flat" alt="Repository views"></a>
  <a href="https://github.com/K1yoshiSho/ispect"><img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/likes/ispect?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/popularity/ispect?logo=flutter" alt="Pub popularity"></a>
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/points/ispect?logo=flutter" alt="Pub points"></a>
</p>

<br>

## 📌 Features

- ✅ Draggable button for route to ISpect page, manage Inspector tools
- ✅ Localizations: ru, en. (I will add more translations in the future.)
- ✅ Talker logger implementation
- ✅ Feedback
- ✅ Debug tools
- ✅ Cache manager
- ✅ Device and app info

## 📌 Getting Started
Follow these steps to use this package

### Add dependency

```yaml
dependencies:
  ispect: ^1.0.5
```

### Add import package

```dart
import 'package:ispect/ispect.dart';
import 'package:talker_flutter/talker_flutter.dart';
```

## Easy to use
Simple example of use `ISpect`<br>
You can manage ISpect using `ISpect.read(context)`.
Put this code in your project at an screen and learn how it works. 😊

<div style="display: flex; flex-direction: row; align-items: flex-start; justify-content: flex-start;">
  <img src="https://github.com/K1yoshiSho/packages_assets/blob/main/assets/preview_usage.gif?raw=true"
  alt="ISpect's example" width="250" style="margin-right: 10px;"/>
</div>

&nbsp;

### Code:

Note: For handle `Dio`: [see](https://pub.dev/packages/talker_dio_logger#usage)  
The simplest realization: 
```dart
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/l10n.dart';
import 'package:talker_flutter/talker_flutter.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final talker = TalkerFlutter.init();

  /// Use global variable [talkerWrapper] for logging.
  talkerWrapper.initHandling(talker: talker);
  talkerWrapper.debug('Hello World!');
  runApp(App(talker: talker));
}

class App extends StatefulWidget {
  final Talker talker;
  const App({super.key, required this.talker});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ISpectOptions options = ISpectOptions(
      talker: widget.talker,
      themeMode: ThemeMode.dark,
      lightTheme: ThemeData.light(),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      locale: const Locale('en'),
    );

    /// It is necessary to wrap `MaterialApp` with `ISpectScopeWrapper`.
    return ISpectScopeWrapper(
      options: options,
      isISpectEnabled: true,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [
          TalkerRouteObserver(widget.talker),
        ],

        /// Add this to `MaterialApp`'s localizationsDelegates for add `ISpect` localization. You can also add your own localization delegates.
        localizationsDelegates: ISpectLocalizations.localizationDelegates([AppGeneratedLocalization.delegate]),
        theme: options.lightTheme,
        darkTheme: options.darkTheme,
        themeMode: options.themeMode,
        builder: (context, child) {
          /// Add this to `MaterialApp`'s builder for add `Draggable ISpect` button.
          child = ISpectBuilder(
            navigatorKey: navigatorKey,
            child: child,
          );

          return child;
        },
        home: const _Home(),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppGeneratedLocalization.of(context).app_title),
            ElevatedButton(
              onPressed: () {
                /// Use `ISpect` to toggle `ISpect` visibility.
                ISpect.read(context).toggleISpect();
              },
              child: const Text('Toggle ISpect'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### For handle routing (GoRouter)
You can use `NavigatorObserver`, but in practice it does not always work correctly.  
Alternatively, you can use a `listener`:

```dart
    _router.routerDelegate.addListener(() {
      final String location =
          _router.routerDelegate.currentConfiguration.last.matchedLocation;
      talkerWrapper.route(location);
    });
```

### For handle providers (Riverpod)
You can use `ProviderObserver`:

```dart
class ProviderLoggerObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    talkerWrapper.provider(
      message: 'Provider ${provider.name} was initialized with $value',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    talkerWrapper.provider(
      message: 'Provider ${provider.name} was disposed',
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    talkerWrapper.provider(
      message:
          'Provider ${provider.name} was updated from $previousValue to $newValue',
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    talkerWrapper.handle(
      exception: error,
      stackTrace: stackTrace,
      message: 'Provider ${provider.name} failed with error $error',
    );
  }
}
```

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
<br>