// ISpect quick start.
//
// Run with the toolkit enabled:
//   flutter run --dart-define=ISPECT_ENABLED=true
//
// Without that flag every entry point is a const no-op and tree-shakes away
// from release builds.
//
// For a full feature tour (custom themes, locales, log generators, Dio/HTTP/DB
// interceptors, observers, etc.) run `lib/complex_example.dart`.

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

// Forward ISpect events to your crash reporter / analytics.
// Wire it into ISpect.run(logger: ISpectFlutter.init(observer: SentryISpectObserver())).
class SentryISpectObserver implements ISpectObserver {
  @override
  void onLog(ISpectLogData data) {/* Sentry.addBreadcrumb(...) */}
  @override
  void onError(ISpectLogData data) {/* Sentry.captureException(...) */}
  @override
  void onException(ISpectLogData data) {/* Sentry.captureException(...) */}
}

void main() {
  // ISpect.run wraps the app in a guarded Zone and installs error handlers
  // (FlutterError, PlatformDispatcher, runZonedGuarded).
  ISpect.run(
    () => runApp(const MyApp()),
    // Provide a custom logger if you need a non-default ISpectFlutter setup.
    // logger: ISpectFlutter.init(observer: SentryISpectObserver()),
    //
    // Lifecycle hooks fire before/after the zoned callback.
    // onInit: () {},
    // onInitialized: () {},
    //
    // Filter out noisy log messages by substring match.
    // filters: ['Heartbeat', 'metrics.tick'],
    //
    // Forward uncaught zone errors to Sentry, Crashlytics, etc.
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
        // Custom theme for the ISpect UI (colors, log icons, page title,
        // custom log types, panel theme).
        // theme: const ISpectTheme(
        //   pageTitle: 'My Diagnostics',
        //   primary: ISpectDynamicColor(
        //     light: Color(0xFF1565C0),
        //     dark: Color(0xFF64B5F6),
        //   ),
        //   // logColors: {'http-request': Colors.blue},
        //   // logIcons: {'http-request': Icons.cloud_upload},
        //   // customLogTypes: [...],
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
          actionItems: [
            ISpectActionItem(
              title: 'Reset cache',
              icon: Icons.refresh,
              description: 'Clears local cache and reloads',
              onTap: (context) => ISpect.logger.info('Cache reset requested'),
            ),
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
    // All log methods are static on ISpect.logger. They all become no-ops
    // when kISpectEnabled is false, so feel free to scatter them in code.
    final logger = ISpect.logger;

    // Adapter packages (add the one(s) you need to pubspec.yaml):
    //   ispectify_dio    — Dio interceptor
    //   ispectify_http   — package:http interceptor
    //   ispectify_ws     — WebSocket logger
    //   ispectify_bloc   — Bloc.observer = ISpectBlocObserver()
    //   ispectify_db     — Database tracing (Hive, SharedPreferences, …)

    return Scaffold(
      appBar: AppBar(title: const Text('ISpect Quick Start')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => logger.info('Hello from ISpect!'),
              child: const Text('info'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => logger.good('Order placed successfully'),
              child: const Text('good'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => logger.warning('Cache nearly full'),
              child: const Text('warning'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => logger.error(
                'Something went wrong',
                exception: StateError('Demo error'),
                stackTrace: StackTrace.current,
              ),
              child: const Text('error'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => logger.track(
                'sign_in_tapped',
                event: 'ui',
                analytics: 'amplitude',
                parameters: const {'screen': 'home'},
              ),
              child: const Text('track (analytics)'),
            ),
            const SizedBox(height: 24),
            const Text('Tap the floating ISpect button to open the panel.'),
            // Other available methods:
            //   logger.debug / verbose / critical / print
            //   logger.route('/home → /details')
            //   logger.provider('AuthProvider rebuilt')
            //   logger.handle(exception: e, stackTrace: st, message: '...')
            //
            // Access the scope model from any widget under ISpectBuilder:
            //   final scope = ISpect.read(context);
            //   scope.toggleISpect(); // show / hide the panel
            //   scope.options = scope.options.copyWith(locale: Locale('ru'));
          ],
        ),
      ),
    );
  }
}
