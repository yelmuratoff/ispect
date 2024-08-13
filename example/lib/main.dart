import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/l10n.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

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
    isPrintLoggingEnabled: true,
    // filters: [
    //   'Handler: "onTap"',
    //   'This exception was thrown because',
    // ],
    onInitialized: () {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: ISpectTalker.talker,
          settings: const TalkerDioLoggerSettings(
              // errorFilter: (response) {
              //   return (response.message?.contains('This exception was thrown because')) == false;
              // },
              ),
        ),
      );
    },
  );
}

class App extends ConsumerWidget {
  final Talker talker;
  const App({super.key, required this.talker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    const locale = Locale('en');

    return ISpectScopeWrapper(
      // theme: const ISpectTheme(
      //   lightBackgroundColor: Colors.white,
      //   darkBackgroundColor: Colors.black,
      //   lightCardColor: Color.fromARGB(255, 241, 240, 240),
      //   darkCardColor: Color.fromARGB(255, 23, 23, 23),
      //   lightDividerColor: Color.fromARGB(255, 218, 218, 218),
      //   darkDividerColor: Color.fromARGB(255, 77, 76, 76),
      // ),

      options: ISpectOptions(
        locale: locale,
        panelItems: [
          ISpectPanelItem(
            icon: Icons.home,
            enableBadge: false,
            onTap: (context) {
              debugPrint('Home');
            },
          ),
        ],
        actionItems: [
          TalkerActionItem(
            title: 'Test',
            icon: Icons.account_tree_rounded,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(
                      child: Text('Test'),
                    ),
                  ),
                ),
              );
            },
            // onTap: (ispectContext) {
            //   Navigator.of(ispectContext).push(
            //     MaterialPageRoute(
            //       builder: (context) => const Scaffold(
            //         body: Center(
            //           child: Text('Test'),
            //         ),
            //       ),
            //     ),
            //   );
            // },
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
        localizationsDelegates: const [
          AppGeneratedLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          ISpectGeneratedLocalization.delegate,
        ],
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
            initialPosition: (x: 0, y: 200),
            // initialJiraData: (
            //   apiToken:
            //       'Token',
            //   domain: 'example',
            //   email: 'name.surname@example.com',
            //   projectId: '00000',
            //   projectKey: 'AAAA'
            // ),
            onPositionChanged: (x, y) {
              debugPrint('x: $x, y: $y');
            },
            onJiraAuthorized: (domain, email, apiToken, projectId, projectKey) {
              // debugPrint(
              //     'From main.dart | domain: $domain, email: $email, apiToken: $apiToken, projectId: $projectId, projectKey: $projectKey');
            },
            child: child,
          );
          // child = DraggableCircularMenu(
          // toggleButtonColor: Colors.blue,
          // toggleButtonBoxShadow: const [],
          // curve: Curves.fastEaseInToSlowEaseOut,
          // reverseCurve: Curves.fastEaseInToSlowEaseOut,
          // items: [
          //   CircularMenuItem(
          //     icon: Icons.home,
          //     color: Colors.green,
          //     onTap: () {},
          //     boxShadow: [],
          //   ),
          //   CircularMenuItem(
          //     icon: Icons.search,
          //     color: Colors.blue,
          //     onTap: () {},
          //     boxShadow: [],
          //   ),
          //   CircularMenuItem(
          //     icon: Icons.settings,
          //     color: Colors.orange,
          //     onTap: () {},
          //     boxShadow: [],
          //   ),
          //   CircularMenuItem(
          //     icon: Icons.chat,
          //     color: Colors.purple,
          //     onTap: () {},
          //     boxShadow: [],
          //   ),
          //   CircularMenuItem(
          //     icon: Icons.notifications,
          //     color: Colors.brown,
          //     onTap: () {},
          //     boxShadow: [],
          //   )
          // ],
          //   child: child!,
          // );
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
              child: const Text('Send print message'),
            ),
          ],
        ),
      ),
    );
  }
}
