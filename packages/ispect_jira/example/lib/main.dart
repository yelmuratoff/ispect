import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_jira/ispect_jira.dart';
import 'package:ispect_jira_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_jira_example/theme_manager.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

// Dio instances
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
      ThemeProvider(
        child: App(talker: talker),
      ),
    ),
    talker: talker,
    isPrintLoggingEnabled: true,
    onInitialized: () {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: ISpect.talker,
          settings: const TalkerDioLoggerSettings(),
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
    ISpectJiraClient.initialize(
      projectDomain: 'anydevkz',
      userEmail: 'y.yelmuratov@astanahub.com',
      apiToken:
          'ATATT3xFfGF0Wy-xun0l77fXjhVtYyEUAMtQSggL8sojVAGiAW-DdR8NP9H0YoRJEho1w2C6b5hPAjW_VA34uqUc0cleVuxL4j2DsbLwzftp7wMTZg_rlZ2UF8vDlMR-TtZcADvPojxR1aR0F0zeo0iM_hDKAAaukpa0PFMonpqucykRL7KMCkY=1D5984A6',
      projectId: '10007',
      projectKey: 'GTMS4',
    );
  }

  @override
  Widget build(BuildContext context) {
    const locale = Locale('en');
    final observer = ISpectNavigatorObserver();

    final themeMode = ThemeProvider.themeMode(context);

    return ISpectScopeWrapper(
      options: ISpectOptions(
        locale: locale,
        panelButtons: [
          ISpectPanelButton(
            icon: Icons.copy_rounded,
            label: 'Token',
            onTap: (context) {
              debugPrint('Token copied');
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
            title: 'ISpect',
            icon: Icons.bug_report_outlined,
            onTap: (context) {
              if (ISpectJiraClient.isInitialized) {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (_) => const JiraSendIssueScreen(),
                    settings: const RouteSettings(
                      name: 'Jira Send Issue Page',
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (_) => JiraAuthScreen(
                      onAuthorized:
                          (domain, email, apiToken, projectId, projectKey) {
                        ISpect.good(
                          '''✅ Jira authorized:
  Project domain: $domain
  User email: $email
  Project id: $projectId
  API token: $apiToken
  Project key: $projectKey''',
                        );
                      },
                    ),
                    settings: const RouteSettings(
                      name: 'Jira Auth Page',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      isISpectEnabled: true,
      child: MaterialApp(
        navigatorObservers: [observer],
        locale: locale,
        supportedLocales: ExampleGeneratedLocalization.supportedLocales,
        localizationsDelegates: ISpectLocalizations.localizationDelegates([
          ExampleGeneratedLocalization.delegate,
          ISpectJiraLocalization.delegate,
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
            feedbackBuilder: (context, onSubmit, controller) =>
                JiraFeedbackBuilder(
              onSubmit: onSubmit,
              theme: Theme.of(context),
              scrollController: controller,
            ),
            initialPosition: (x: 0, y: 200),
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
