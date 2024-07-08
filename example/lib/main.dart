import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/l10n.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final themeProvider =
    StateNotifierProvider<ThemeManager, ThemeMode>((ref) => ThemeManager());

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
  ISpectTalker.initHandling(talker: talker);
  ISpectTalker.debug('Hello World!');

  dio.interceptors.add(TalkerDioLogger(
    talker: ISpectTalker.talker,
    settings: const TalkerDioLoggerSettings(
        // printRequestHeaders: true,
        // printResponseHeaders: true,
        ),
  ));

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
    const options = ISpectOptions(
      locale: Locale('ru'),
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
          ],
        ),
      ),
    );
  }
}
