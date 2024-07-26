<div align="center">
<p align="center">
    <a href="https://github.com/K1yoshiSho/ispect" align="center">
        <img src="https://github.com/K1yoshiSho/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> A package combining Inspector, Talker, and more from pub.dev for efficient project implementation. 🚀 </h2>

<p align="center">
This package is not meant to be a groundbreaking innovation but rather a curated collection of high-quality tools from pub.dev, tailored for my future projects. I've decided to share it with the community in hopes it might be of use to others. It combines time-tested utilities and my personal enhancements aimed at improving project efficiency and adaptability.

As the underlying packages evolve, I plan to update and enhance this package, possibly adding new features based on community feedback and emerging needs. This package is meant to be a dynamic toolset that grows and improves over time, facilitating smoother development processes for Flutter developers.

Your feedback is highly valued as it will help shape future updates and ensure the package remains relevant and useful. 😊


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
- ✅ Localizations: ru, en, kk. (I will add more translations in the future.)
- ✅ Talker logger implementation: BLoC, Dio, Routing, Provider
- ✅ You can customize more options during initialization of ISpectTalker like BLoC, Dispatcher error and etc.
- ✅ Updated ISpectTalker page: added more options.
   - Detailed HTTP logs: request, response, error
   - Debug tools
   - Cache manager
   - Device and app info
- ✅ Feedback
- ✅ Performance tracker

## 📌 Getting Started
Follow these steps to use this package

### Add dependency

```yaml
dependencies:
  ispect: ^1.6.5
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
  <img src="https://github.com/K1yoshiSho/packages_assets/blob/main/assets/ispect/ispect_preview.gif?raw=true"
  alt="ISpect's example" width="250" style="margin-right: 10px;"/>
</div>

&nbsp;

### Code:

Note: For handle `Dio`: [see](https://pub.dev/packages/talker_dio_logger#usage)  
The simplest realization: 
```dart
final navigatorKey = GlobalKey<NavigatorState>();

final themeProvider = StateNotifierProvider<ThemeManager, ThemeMode>((ref) => ThemeManager());

final dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

class ThemeManager extends StateNotifier<ThemeMode> {
  ThemeManager() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode themeMode) {
    state = themeMode;
  }

  ThemeMode get themeMode => state;
}

void main() {
  final talker = TalkerFlutter.init();

  ISpect.run(
    () => runApp(
      ProviderScope(
        observers: [
          TalkerRiverpodObserver(
            talker: talker,
            settings: const TalkerRiverpodLoggerSettings(),
          ),
        ],
        child: App(talker: talker),
      ),
    ),
    talker: talker,
    onInitialized: () {
      dio.interceptors.add(TalkerDioLogger(
        talker: ISpectTalker.talker,
      ));
    },
  );
}

class App extends ConsumerWidget {
  final Talker talker;
  const App({super.key, required this.talker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    const locale = Locale('ru');

    return ISpectScopeWrapper(
      options: ISpectOptions(
        locale: locale,
        actionItems: [
          TalkerActionItem(
            title: 'Test',
            icon: Icons.account_tree_rounded,
            onTap: (ispectContext) {
              Navigator.of(ispectContext).push(
                MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(
                      child: Text('Test'),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      isISpectEnabled: true,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [
          TalkerRouteObserver(talker),
        ],
        locale: locale,
        supportedLocales: AppGeneratedLocalization.delegate.supportedLocales,
        localizationsDelegates: ISpectLocalizations.localizationDelegates([
          AppGeneratedLocalization.delegate,
        ]),
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: themeMode,
        builder: (context, child) {
          child = ISpectBuilder(
            navigatorKey: navigatorKey,
            initialPosition: (0, 300),
            onPositionChanged: (x, y) {
              debugPrint('x: $x, y: $y');
            },
            child: child,
          );
          return child;
        },
        home: const _Home(),
      ),
    );
  }
}

class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider.notifier);
    final iSpect = ISpect.read(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppGeneratedLocalization.of(context).app_title),
            ElevatedButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
                // iSpect.setThemeMode(themeNotifier.themeMode);
              },
              child: const Text('Toggle theme'),
            ),
            ElevatedButton(
              onPressed: () {
                iSpect.toggleISpect();
              },
              child: const Text('Toggle ISpect'),
            ),
            ElevatedButton(
              onPressed: () {
                dio.get('/posts/1');
              },
              child: const Text('Send HTTP request'),
            ),
            ElevatedButton(
              onPressed: () {
                dio.get('/post3s/1');
              },
              child: const Text('Send HTTP request with error'),
            ),
            ElevatedButton(
              onPressed: () {
                dio.options.headers.addAll({
                  'Authorization': 'Bearer token',
                });
                dio.get('/posts/1');
                dio.options.headers.remove('Authorization');
              },
              child: const Text('Send HTTP request with Token'),
            ),
            ElevatedButton(
              onPressed: () {
                throw Exception('Test exception');
              },
              child: const Text('Throw exception'),
            ),
            ElevatedButton(
                onPressed: () {
                  debugPrint('Send print message');
                },
                child: const Text('Send print message')),
          ],
        ),
      ),
    );
  }
}
```

### For change `ISpect` theme:
```dart
ISpect.read(context).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
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

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
<br>