import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

void main() {
  // ISpect.run wraps the app in a guarded Zone and installs error handlers.
  // Build with `--dart-define=ISPECT_ENABLED=true` to enable; without the
  // flag every ISpect entry point is a no-op and gets tree-shaken away.
  ISpect.run(
    () => runApp(const MyApp()),
    // Provide a custom logger if you need a non-default ISpectFlutter setup.
    // logger: ISpectFlutter.init(),
    //
    // Lifecycle hooks fire before/after the zoned callback.
    // onInit: () {},
    // onInitialized: () {},
    //
    // Filter out noisy log messages by substring match.
    // filters: ['Heartbeat', 'metrics.tick'],
    //
    // Forward errors to Sentry, Crashlytics, etc.
    // onZonedError: (e, st) => Sentry.captureException(e, stackTrace: st),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Keep the observer in State so it survives rebuilds — it captures route
  // history for the ISpect panel and must not be re-created per build.
  final _ispectObserver = ISpectNavigatorObserver();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISpect Quick Start',
      navigatorObservers: ISpectNavigatorObserver.observers(
        observer: _ispectObserver,
        additional: [
          // Your custom NavigatorObservers (analytics, deep links, etc.)
        ],
      ),
      localizationsDelegates: [
        // Your app delegates (e.g. GlobalMaterialLocalizations.delegate)
        ...ISpectLocalizations.delegate(),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (_, child) => ISpectBuilder.wrap(
        child: child!,
        // Set to false to hide the panel for non-admin users at runtime.
        // Compile-time gating already happens via kISpectEnabled.
        // isISpectEnabled: currentUser.isAdmin,
        //
        // Custom theme for the ISpect UI (colors, log icons, page title).
        // theme: const ISpectTheme(
        //   pageTitle: 'My Diagnostics',
        //   primary: ISpectDynamicColor(
        //     light: Color(0xFF1565C0),
        //     dark: Color(0xFF64B5F6),
        //   ),
        // ),
        options: ISpectOptions(
          observer: _ispectObserver,
          // Default locale of the ISpect UI.
          locale: const Locale('en'),
          // Toggle individual tools off if you don't need them.
          isLogPageEnabled: true,
          isPerformanceEnabled: true,
          isInspectorEnabled: true,
          isColorPickerEnabled: true,
          onOpenFile: (path) async {
            // Open exported log files (e.g. via package:open_filex).
          },
          onShare: (request) async {
            // Send sessions/logs out (e.g. via package:share_plus).
            // request.text / request.subject / request.filePaths
          },
          onLoadLogContent: (path) async {
            // Return raw text from a file when the user imports a session.
            return null;
          },
          onSettingsChanged: (settings) {
            // Here you can save changed settings to local storage
            // e.g. prefs.setString('ispect', jsonEncode(settings.toJson()));
          },
          // Here you can attach saved settings from local storage
          initialSettings: null,
          // Add custom buttons to the action sheet (logs export, share, etc.).
          actionItems: const [
            // ISpectActionItem(title: 'Reset cache', icon: Icons.refresh, onTap: ...),
          ],
          // Extra buttons on the bottom of the draggable panel.
          panelButtons: const [
            // DraggablePanelButtonItem(icon: Icons.bug_report, label: 'Bug', onTap: ...),
          ],
          // Icon-only items on the draggable panel.
          panelItems: const [
            // DraggablePanelItem(icon: Icons.cookie, onTap: ...),
          ],
          // Plug in custom inspector pages (see InspectorPlugin).
          plugins: const [],
          // Replace the default log card rendering completely.
          // logBuilder: (context, log) => MyCustomLogCard(log: log),
        ),
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
              onPressed: () => ISpect.logger.warning('Cache nearly full'),
              child: const Text('Log warning'),
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
