import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

void main() {
  // Initialize ISpectify for logging
  final logger = ISpectifyFlutter.init();

  // Wrap your app with ISpect
  ISpect.run(
    () => runApp(MyApp()),
    logger: logger,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.localizationDelegates([
        // Add your localization delegates here
      ]),
      builder: (context, child) => ISpectBuilder(
        options: ISpectOptions(
          locale: const Locale('en'),
          isFeedbackEnabled: true,
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
          lightBackgroundColor: Colors.white,
          darkBackgroundColor: Colors.black,
          lightDividerColor: Colors.grey.shade300,
          darkDividerColor: Colors.grey.shade800,
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
          child: ElevatedButton(
            onPressed: () {
              ISpect.logger.info('Button pressed!');
            },
            child: const Text('Press me'),
          ),
        ),
      ),
    );
  }
}
