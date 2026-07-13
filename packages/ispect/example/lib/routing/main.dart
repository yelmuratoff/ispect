import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/examples/example_app.dart';

void main() {
  final logger = ISpectFlutter.init();
  final navigatorObserver = ISpectNavigatorObserver();
  ISpect.run(
    () => runApp(
      buildExampleApp(
        title: 'ISpect navigation example',
        observer: navigatorObserver,
        home: const _RoutingPage(),
      ),
    ),
    logger: logger,
  );
}

final class _RoutingPage extends StatelessWidget {
  const _RoutingPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Navigation diagnostics')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Second route')),
                ),
              ),
            ),
            child: const Text('Push a route'),
          ),
        ),
      );
}
