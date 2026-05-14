import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

void main() {
  ISpect.run(() => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _ispectObserver = ISpectNavigatorObserver();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISpect Quick Start',
      navigatorObservers: ISpectNavigatorObserver.observers(
          observer: _ispectObserver,
          additional: [
            // Your custom observers
          ]),
      localizationsDelegates: [
        // Your app delegates
        ...ISpectLocalizations.delegate(),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (_, child) => ISpectBuilder.wrap(
        child: child!,
        options: ISpectOptions(observer: _ispectObserver),
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISpect Quick Start')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => ISpect.logger.info('Hello from ISpect!'),
              child: const Text('Log info'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ISpect.logger.error(
                'Something went wrong',
                exception: StateError('Demo error'),
                stackTrace: StackTrace.current,
              ),
              child: const Text('Log error'),
            ),
            const SizedBox(height: 24),
            const Text('Tap the floating ISpect button to open the panel.'),
          ],
        ),
      ),
    );
  }
}
