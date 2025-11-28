import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

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
  // Example: Restore settings from storage (e.g., SharedPreferences)
  // final prefs = await SharedPreferences.getInstance();
  // final settingsJson = prefs.getString('ispect_settings');
  // final initialSettings = settingsJson != null
  //     ? ISpectSettingsState.fromJson(jsonDecode(settingsJson))
  //     : null;

  final logger = ISpectFlutter.init();

  logger.addObserver(SentryISpectObserver());
  logger.addObserver(BackendISpectObserver());

  // Wrap your app with ISpect
  ISpect.run(logger: logger, () => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(delegates: [
        // Add your localization delegates here
      ]),
      navigatorObservers: [observer],
      builder: (context, child) => ISpectBuilder(
        options: ISpectOptions(
          observer: observer,

          // This parameter is needed if you want the user to be able to manage settings
          // Example: Restore initial settings from storage
          // initialSettings: initialSettings,
          initialSettings: const ISpectSettingsState(
            disabledLogTypes: {
              'warning',
            },
            enabled: true,
            useConsoleLogs: true,
            useHistory: true,
          ),
          locale: const Locale('en'),

          onSettingsChanged: (settings) {
            // Persist settings when they change
            ISpect.logger.print('ISpect settings changed: $settings');
            // Example: Save to SharedPreferences
            // final prefs = await SharedPreferences.getInstance();
            // await prefs.setString('ispect_settings', jsonEncode(settings.toJson()));
          },
          onLoadLogContent: (context) async {
            // Here you can load log content.
            // For example, from a file using file_picker.
            return 'Loaded log content from callback';
          },
          onOpenFile: (path) async {
            // Here you can handle opening the file.
            // For example, using open_filex package.
            await OpenFilex.open(path);
          },
          onShare: (ISpectShareRequest request) async {
            // Here you can handle sharing the content.
            // For example, using share_plus package.
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
              onTap: (context) {
                // Handle settings tap
              },
            ),
          ],
          panelButtons: [
            DraggablePanelButtonItem(
              icon: Icons.info,
              label: 'Info',
              onTap: (context) {
                // Handle info tap
              },
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
            'error': Colors.red,
            'info': Colors.blue,
          },
          logIcons: {
            'error': Icons.error,
            'info': Icons.info,
          },
          logDescriptions: [
            LogDescription(
              key: 'riverpod-add',
              isDisabled: true,
            ),
            LogDescription(
              key: 'riverpod-update',
              isDisabled: true,
            ),
            LogDescription(
              key: 'riverpod-dispose',
              isDisabled: true,
            ),
            LogDescription(
              key: 'riverpod-fail',
              isDisabled: true,
            ),
          ],
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpect Example')),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  ISpect.logger.info('Button pressed!');
                  ISpect.logger.warning('Button pressed!');
                  ISpect.logger.error('Button pressed!');
                },
                child: const Text('Press me'),
              ),
              ElevatedButton(
                onPressed: () {
                  ISpect.logger.handle(
                    exception: Exception('Test Exception'),
                    stackTrace: StackTrace.current,
                  );
                },
                child: const Text('Large Error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
