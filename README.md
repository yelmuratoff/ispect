<div align="center">
<p align="center">
    <a href="https://github.com/K1yoshiSho/ispect" align="center">
        <img src="https://github.com/K1yoshiSho/ispect/blob/main/assets/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> Wrapper around Inspector, Talker and etc 🚀 </h2>

<p align="center">
Description 😊
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

- ✅ Draggable button
- ✅ Talker logger implementation
- ✅ Feedback
- ✅ Inspector
- ✅ Debug tools
- ✅ Cache manager
- ✅ Device and app info

## 📌 Getting Started
Follow these steps to use this package

### Add dependency

```yaml
dependencies:
  ispect: ^0.0.1
```

### Add import package

```dart
import 'package:ispect/ispect.dart';
import 'package:talker_flutter/talker_flutter.dart';
```

### Easy to use
Simple example of use `ISpect`<br>
Put this code in your project at an screen and learn how it works 😊

<div style="display: flex; flex-direction: row; align-items: flex-start; justify-content: flex-start;">
  <img src="https://github.com/K1yoshiSho/ispect/blob/main/assets/screenshot.png?raw=true"
  alt="ISpect's example" width="250" style="margin-right: 10px;"/>
</div>

&nbsp;

Widget part:
```dart
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:talker_flutter/talker_flutter.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final talker = TalkerFlutter.init();
  talker.debug('Hello World!');
  runApp(App(talker: talker));
}

class App extends StatefulWidget {
  final Talker talker;
  const App({super.key, required this.talker});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ISpectController controller = ISpectController();

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
      locale: const Locale('ru'),
      controller: controller,
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData.light(),
      darkTheme: options.darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        child = ISpectWrapper(
          navigatorKey: navigatorKey,
          options: options,
          child: child,
        );

        return child;
      },
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hello World!'),
      ),
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