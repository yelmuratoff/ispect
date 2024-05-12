import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:provider/provider.dart';
import 'package:ispect_example/src/core/localization/generated/l10n.dart';
import 'package:talker_flutter/talker_flutter.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final talker = TalkerFlutter.init();

  /// Use global variable [talkerWrapper] for logging.
  talkerWrapper.initHandling(talker: talker);
  talkerWrapper.debug('Hello World!');
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: App(talker: talker),
    ),
  );
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final options = ISpectOptions(
      themeMode: themeProvider.themeMode,
      lightTheme: ThemeData.from(
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
        localizationsDelegates: ISpectLocalizations.localizationDelegates(
            [AppGeneratedLocalization.delegate]),
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
        themeMode: themeProvider.themeMode,
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final iSpect = ISpect.read(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppGeneratedLocalization.of(context).app_title),
            ElevatedButton(
              onPressed: () {
                themeProvider.toggleTheme();
                iSpect.setThemeMode(themeProvider.themeMode);
              },
              child: const Text('Toggle theme'),
            ),
            ElevatedButton(
              onPressed: () {
                /// Use `ISpect` to toggle `ISpect` visibility.
                iSpect.toggleISpect();
              },
              child: const Text('Toggle ISpect'),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
