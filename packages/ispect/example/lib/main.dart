import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class SentryISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) => log('Sentry onError: ${err.message}');
  @override
  void onException(ISpectLogData err) =>
      log('Sentry onException: ${err.message}');
  @override
  void onLog(ISpectLogData data) => log('Sentry onLog: ${data.message}');
}

void main() {
  final logger = ISpectFlutter.init();
  logger.addObserver(SentryISpectObserver());
  ISpect.run(logger: logger, () => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers: ISpectNavigatorObserver.observers(),
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      builder: (_, child) => ISpectBuilder.wrap(
        child: child!,
        options: ISpectOptions(
          onOpenFile: (path) async => OpenFilex.open(path),
          onShare: (req) async => SharePlus.instance.share(ShareParams(
            text: req.text,
            subject: req.subject,
            files: req.filePaths.map(XFile.new).toList(),
          )),
        ),
        theme: ISpectTheme(pageTitle: 'Debug'),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISpect Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ISpect: ${kISpectEnabled ? "ENABLED" : "DISABLED"}',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ISpect.logger.info('Info message!'),
              icon: const Icon(Icons.info),
              label: const Text('Log Info'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ISpect.logger.warning('Warning!'),
              icon: const Icon(Icons.warning),
              label: const Text('Log Warning'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ISpect.logger.error('Error!'),
              icon: const Icon(Icons.error),
              label: const Text('Log Error'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ISpect.logger.handle(
                exception: Exception('Test'),
                stackTrace: StackTrace.current,
              ),
              icon: const Icon(Icons.dangerous),
              label: const Text('Exception'),
            ),
          ],
        ),
      ),
    );
  }
}
