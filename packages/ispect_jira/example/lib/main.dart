import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_jira/ispect_jira.dart';
import 'package:ispect_jira_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_jira_example/theme_manager.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
      projectDomain: 'domain',
      userEmail: 'example@example.com',
      apiToken: 'token',
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
                ISpect.good('Good log');
                ISpect.info('Info log');
                ISpect.warning('Warning log');
              },
              child: const Text('Print some logs'),
            ),
          ],
        ),
      ),
    );
  }
}
