import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_ai/ispect_ai.dart';
import 'package:ispect_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_example/theme_manager.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

// Dio instances
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

void main() {
  final iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(
      ThemeProvider(
        child: App(iSpectify: iSpectify),
      ),
    ),
    logger: iSpectify,
    isPrintLoggingEnabled: true,
    onInitialized: () {
      dio.interceptors.add(
        ISpectifyDioLogger(
          iSpectify: iSpectify,
        ),
      );
    },
  );
}

class App extends StatefulWidget {
  final ISpectify iSpectify;
  const App({super.key, required this.iSpectify});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    ISpectGoogleAi.init('token');
  }

  @override
  Widget build(BuildContext context) {
    const locale = Locale('en');
    final observer = ISpectNavigatorObserver();

    final themeMode = ThemeProvider.themeMode(context);

    return MaterialApp(
      navigatorObservers: [observer],
      locale: locale,
      supportedLocales: ExampleGeneratedLocalization.supportedLocales,
      localizationsDelegates: ISpectLocalizations.localizationDelegates([
        ExampleGeneratedLocalization.delegate,
        ISpectAILocalization.delegate,
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
          observer: observer,
          options: ISpectOptions(
            locale: locale,
            actionItems: [
              ISpectifyActionItem(
                title: 'AI Chat',
                icon: Icons.bubble_chart,
                onTap: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AiChatPage(),
                    ),
                  );
                },
              ),
              ISpectifyActionItem(
                title: 'AI Reporter',
                icon: Icons.report_rounded,
                onTap: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AiReporterPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          isISpectEnabled: true,
          initialPosition: (x: 0, y: 200),
          onPositionChanged: (x, y) {
            debugPrint('x: $x, y: $y');
          },
          child: child ?? const SizedBox.shrink(),
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
    final themeMode = ThemeProvider.themeMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(ExampleGeneratedLocalization.of(context)!.app_title),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () {
              ThemeProvider.toggleTheme(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
