import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/l10n.dart';
import 'package:ispect_example/src/logs/success.dart';

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

final dummyDio = Dio(
  BaseOptions(
    baseUrl: 'https://api.escuelajs.co',
  ),
);

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
    // isFlutterPrintEnabled: false,
    // filters: [
    //   'Handler: "onTap"',
    //   'This exception was thrown because',
    // ],
    onInitialized: () {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: ISpect.talker,
          settings: const TalkerDioLoggerSettings(
              // errorFilter: (response) {
              //   return (response.message?.contains('This exception was thrown because')) == false;
              // },
              ),
        ),
      );
      dummyDio.interceptors.add(
        TalkerDioLogger(
          talker: ISpect.talker,
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
    const locale = Locale('ru');

    return ISpectScopeWrapper(
      // theme: const ISpectTheme(
      //   lightBackgroundColor: Colors.white,
      //   darkBackgroundColor: Colors.black,
      //   lightCardColor: Color.fromARGB(255, 241, 240, 240),
      //   darkCardColor: Color.fromARGB(255, 23, 23, 23),
      //   lightDividerColor: Color.fromARGB(255, 218, 218, 218),
      //   darkDividerColor: Color.fromARGB(255, 77, 76, 76),
      // ),
      theme: ISpectTheme(
        logColors: {
          SuccessLog.logKey: const Color(0xFF880E4F),
        },
        logIcons: {
          // TalkerLogType.route.key: Icons.router_rounded,
          SuccessLog.logKey: Icons.check_circle_rounded,
        },
      ),
      options: ISpectOptions(
        locale: locale,
        // Use it if you need to use Google AI helper for generating logs description,
        // and logs report.
        googleAiToken: null,
        panelButtons: [
          ISpectPanelButton(
            icon: Icons.copy_rounded,
            label: 'Token',
            onTap: (context) {
              debugPrint('Token copied');
            },
          ),
          ISpectPanelButton(
            icon: Icons.copy_rounded,
            label: 'FCM token',
            onTap: (context) {
              debugPrint('FCM token copied');
            },
          ),
        ],
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
          ISpectNavigatorObserver(
            isLogModals: false,
          ),
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
      appBar: AppBar(
        title: Text(AppGeneratedLocalization.of(context).app_title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              child: const Text('Toggle theme'),
            ),
            ElevatedButton(
              onPressed: () {
                ISpect.track('Toggle ISpect', parameters: {
                  'isISpectEnabled': iSpect.isISpectEnabled,
                });
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
                final formData = FormData();
                formData.files.add(MapEntry(
                  'file',
                  MultipartFile.fromBytes(
                    [1, 2, 3],
                    filename: 'file.txt',
                  ),
                ));

                dummyDio.post(
                  '/api/v1/files/upload',
                  data: formData,
                );
              },
              child: const Text('Upload file to dummy server'),
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const _SecondPage(),
                  ),
                );
              },
              child: const Text('Go to second page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const _SecondPage(),
                  ),
                );
              },
              child: const Text('Replace with second page'),
            ),
            ElevatedButton(
              onPressed: () {
                ISpect.logTyped(SuccessLog('Success log'));
              },
              child: const Text('Success log'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const _Home(),
              ),
            );
          },
          child: const Text('Go to Home'),
        ),
      ),
    );
  }
}

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
