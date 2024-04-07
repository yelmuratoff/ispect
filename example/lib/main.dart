import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:talker_flutter/talker_flutter.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final talker = TalkerFlutter.init();
  talker.debug('Hello World!');
  ISpectTalker.initHandling(talker: talker);
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
      locale: const Locale('en'),
      controller: controller,
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [
        TalkerRouteObserver(widget.talker),
      ],
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
