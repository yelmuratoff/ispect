import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/l10n.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final themeProvider =
    StateNotifierProvider<ThemeManager, ThemeMode>((ref) => ThemeManager());

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
  talkerWrapper.initHandling(talker: talker);
  talkerWrapper.debug('Hello World!');
  runApp(
    ProviderScope(
      observers: [
        TalkerRiverpodObserver(
          talker: talker,
          settings: const TalkerRiverpodLoggerSettings(),
        ),
      ],
      child: App(talker: talker),
    ),
  );
}

class App extends ConsumerWidget {
  final Talker talker;
  const App({super.key, required this.talker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final options = ISpectOptions(
      themeMode: themeMode,
      locale: const Locale('ru'),
    );

    return ISpectScopeWrapper(
      options: options,
      isISpectEnabled: true,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [
          TalkerRouteObserver(talker),
        ],
        locale: options.locale,
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
    final themeNotifier = ref.watch(themeProvider.notifier);
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
                iSpect.setThemeMode(themeNotifier.themeMode);
              },
              child: const Text('Toggle theme'),
            ),
            ElevatedButton(
              onPressed: () {
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
