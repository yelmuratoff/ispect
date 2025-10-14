import 'package:auto_route/auto_route.dart';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

import 'autoroute_example.gr.dart';

class SecondNavObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('SecondNavObserver: Pushed ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('SecondNavObserver: Popped ${route.settings.name}');
  }
}

final observer = ISpectNavigatorObserver();
void main() {
  final logger = ISpectifyFlutter.init();
  ISpect.run(
    logger: logger,
    () => runApp(NestedNavigationApp()),
  );
}

class NestedNavigationApp extends StatelessWidget {
  NestedNavigationApp({super.key});

  final nestedRouter = NestedRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: ISpectLocalizations.delegates(),
      routerConfig: nestedRouter.config(
        navigatorObservers: () => [nestedRouter.observer, observer],
      ),
      builder: (context, child) {
        return ISpectBuilder(
          options: ISpectOptions(
            observer: observer,
          ),
          child: child!,
        );
      },
    );
  }
}

@AutoRouterConfig()
class NestedRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute(page: SecondRoute.page, children: [
          AutoRoute(page: HostRoute.page),
        ]),
      ];

  SecondNavObserver get observer => SecondNavObserver();
}

@RoutePage()
class HostScreen extends StatelessWidget {
  const HostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Host Screen'),
        leading: AutoLeadingButton(),
      ),
    );
  }
}

@RoutePage()
class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.pushRoute(SecondRoute());
          },
          child: Text('Go to second screen'),
        ),
      ),
    );
  }
}

@RoutePage()
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.maybePop(),
              child: Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  builder: (context) => Container(
                    height: 200,
                    color: Colors.amber,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        child: Text('Close modal'),
                      ),
                    ),
                  ),
                );
              },
              child: Text('Show modal'),
            ),
          ],
        ),
      ),
    );
  }
}
