import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

// Define a constant based on a build-time flag
const bool kEnableISpect = bool.fromEnvironment(
  'ENABLE_ISPECT',
  defaultValue: false,
);

class SentryISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) {
    log('SentryISpectObserver - onError: ${err.message}');
  }

  @override
  void onException(ISpectLogData err) {
    log('SentryISpectObserver - onException: ${err.message}');
  }

  @override
  void onLog(ISpectLogData data) {
    log('SentryISpectObserver - onLog: ${data.message}');
  }
}

class BackendISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) {
    log('BackendISpectObserver - onError: ${err.message}');
  }

  @override
  void onException(ISpectLogData err) {
    log('BackendISpectObserver - onException: ${err.message}');
  }

  @override
  void onLog(ISpectLogData data) {
    log('BackendISpectObserver - onLog: ${data.message}');
  }
}

final observer = ISpectNavigatorObserver();

void main() {
  if (kEnableISpect) {
    // ISpect is only initialized when the flag is true
    final logger = ISpectFlutter.init(
      options: ISpectLoggerOptions(
        customColors: {
          'error': AnsiPen()..yellow(),
          'exception': AnsiPen()..yellow(),
          'info': AnsiPen()..blue(),
        },
      ),
    );

    logger.addObserver(SentryISpectObserver());
    logger.addObserver(BackendISpectObserver());

    ISpect.run(logger: logger, () => runApp(const MyApp()));
  } else {
    // Normal app startup without ISpect
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates:
          kEnableISpect ? ISpectLocalizations.delegates(delegates: []) : [],
      theme: ThemeData(
        dividerColor: Colors.grey.shade300,
      ),
      darkTheme: ThemeData(
        dividerColor: Colors.grey.shade800,
      ),
      navigatorObservers: kEnableISpect ? [observer] : [],
      builder: (context, child) {
        if (kEnableISpect) {
          return ISpectBuilder(
            options: ISpectOptions(
              observer: observer,
              initialSettings: const ISpectSettingsState(
                disabledLogTypes: {
                  'riverpod-add',
                  'riverpod-update',
                  'riverpod-dispose',
                  'riverpod-fail',
                },
                enabled: true,
                useConsoleLogs: true,
                useHistory: true,
              ),
              locale: const Locale('en'),
              onSettingsChanged: (settings) {
                ISpect.logger.print('ISpect settings changed: $settings');
              },
              onLoadLogContent: (context) async {
                return 'Loaded log content from callback';
              },
              onOpenFile: (path) async {
                await OpenFilex.open(path);
              },
              onShare: (ISpectShareRequest request) async {
                final filesPath = request.filePaths;
                final files = <XFile>[];
                for (final path in filesPath) {
                  files.add(XFile(path));
                }
                await SharePlus.instance.share(ShareParams(
                  text: request.text,
                  subject: request.subject,
                  files: files,
                ));
              },
              actionItems: [
                ISpectActionItem(
                    onTap: (BuildContext context) {},
                    title: 'Some title here',
                    icon: Icons.add),
              ],
              panelItems: [
                DraggablePanelItem(
                  enableBadge: false,
                  icon: Icons.settings,
                  onTap: (context) {},
                ),
              ],
              panelButtons: [
                DraggablePanelButtonItem(
                  icon: Icons.info,
                  label: 'Info',
                  onTap: (context) {},
                ),
              ],
            ),
            theme: ISpectTheme(
              pageTitle: 'Your name here',
              primary: ISpectDynamicColor(
                light: Colors.red,
                dark: Colors.red,
              ),
              background: ISpectDynamicColor(
                light: Colors.redAccent.shade100,
                dark: Colors.black,
              ),
              card: ISpectDynamicColor(
                light: Colors.redAccent.shade200,
                dark: Colors.grey.shade900,
              ),
              divider: ISpectDynamicColor(
                light: Colors.redAccent.shade400,
                dark: Colors.grey.shade800,
              ),
              logColors: {
                'error': Colors.yellow,
                'exception': Colors.yellow,
                'info': Colors.blue,
              },
              logIcons: {
                'error': Icons.abc,
                'exception': Icons.abc,
                'info': Icons.info,
              },
            ),
            child: child ?? const SizedBox.shrink(),
          );
        }
        return child ?? const SizedBox.shrink();
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpect Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (kEnableISpect) {
                    ISpect.logger.info('Button pressed!');
                    ISpect.logger.warning('Button pressed!');
                    ISpect.logger.error('Button pressed!');
                  } else {
                    debugPrint('Button pressed! (ISpect disabled)');
                  }
                },
                child: const Text('Press me'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (kEnableISpect) {
                    ISpect.logger.handle(
                      exception: Exception('Test Exception'),
                      stackTrace: StackTrace.current,
                    );
                  } else {
                    debugPrint('Error logged! (ISpect disabled)');
                  }
                },
                child: const Text('Large Error'),
              ),
              const SizedBox(height: 20),
              Text(
                'ISpect: ${kEnableISpect ? "ENABLED" : "DISABLED"}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
