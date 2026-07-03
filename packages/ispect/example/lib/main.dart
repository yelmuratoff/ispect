// ISpect quick start.
//
// Run with the toolkit enabled:
//   flutter run --dart-define=ISPECT_ENABLED=true
//
// Without that flag every entry point is a const no-op and tree-shakes away
// from release builds.
//
// What this file shows:
//   • Guarded startup via ISpect.run (FlutterError + zone error handlers).
//   • Every ISpect.logger level (info/good/warning/error/debug/critical/…).
//   • The standalone JSON viewer screen.
//   • The HTTP composer ("mini-Postman") — wired through onPickComposerFile.
//   • Environment metadata in exported logs — wired through metadataProvider.
//
// For a deeper tour (custom themes, locales, Dio/HTTP/WS/DB interceptors,
// Riverpod/Bloc observers, stress tests, compact network URLs, jank logging)
// run `lib/complex_example.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    //
    // Granular hooks (all optional): onFlutterError, onPlatformDispatcherError,
    // onPresentError, onUncaughtError, the isPrintLoggingEnabled /
    // isFlutterPrintEnabled / isZoneErrorHandlingEnabled toggles, and
    // options: ISpectErrorHandlerOptions(...).
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
      supportedLocales: ISpectGeneratedLocalization.supportedLocales,
      localizationsDelegates: [
        ...ISpectKurdishLocalizations.delegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
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
          // Route severe-jank frames into the log viewer. Off by default to
          // avoid spam; severeJankFactor (default 2.0) sets the threshold.
          enableJankLogging: false,
          // severeJankFactor: 2.0,
          // Environment metadata shown in the header of exported/shared logs.
          // Supply values you already own (package_info_plus / device_info_plus
          // / --dart-define); ISpect never collects them. Resolution may be
          // async; keep tokens and PII out.
          metadataProvider: () => const ISpectMetadata(
            appName: 'ISpect Quick Start',
            appVersion: '1.0.0',
            buildNumber: '1',
            environment: 'dev',
          ),
          // Supplies a file for multipart bodies in the HTTP composer. A real
          // app picks one here, e.g. with package:file_picker:
          //
          //   final result = await FilePicker.platform.pickFiles(withData: true);
          //   if (result == null) return null; // user cancelled
          //   final file = result.files.single;
          //   return ComposerPickedFile(
          //     filename: file.name,
          //     bytes: file.bytes!,
          //     contentType: lookupMimeType(file.name) ?? 'application/octet-stream',
          //   );
          //
          // This stub returns in-memory bytes so the "attach file" control
          // works without a native picker. Omit the callback to hide it.
          onPickComposerFile: () async => ComposerPickedFile(
            filename: 'sample.txt',
            bytes: 'Hello from the ISpect HTTP composer'.codeUnits,
            contentType: 'text/plain',
          ),
          onOpenFile: (path) async {
            // Open exported log files (e.g. via package:open_filex).
          },
          onShare: (request) async {
            // Send sessions/logs out (e.g. via package:share_plus).
            // request.text / request.subject / request.filePaths
          },
          onLoadLogContent: (context) async {
            // Return raw text from a file/clipboard when importing a session.
            // Returning null cancels without an error.
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
          // Replace the whole draggable panel (see ISpectPanelData / panelBuilder).
          // panelBuilder: (context, data) => DraggablePanel(
          //   controller: data.controller,
          //   items: data.items,
          //   buttons: data.buttons,
          //   theme: data.theme,
          //   child: data.child,
          // ),
          //
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
    //   ispectify_riverpod — ProviderObserver = ISpectRiverpodObserver()
    //   ispectify_db     — Database tracing (Hive, SharedPreferences, …)

    return Scaffold(
      appBar: AppBar(title: const Text('ISpect Quick Start')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionTitle('Log levels'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => logger.info('Hello from ISpect!'),
                child: const Text('info'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.good('Order placed successfully'),
                child: const Text('good'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.warning('Cache nearly full'),
                child: const Text('warning'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.debug('Reached checkout step 2'),
                child: const Text('debug'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.error(
                  'Something went wrong',
                  exception: StateError('Demo error'),
                  stackTrace: StackTrace.current,
                ),
                child: const Text('error'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.critical('Payment gateway unreachable'),
                child: const Text('critical'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.route('/home → /details'),
                child: const Text('route'),
              ),
              FilledButton.tonal(
                onPressed: () => logger.track(
                  'sign_in_tapped',
                  event: 'ui',
                  analytics: 'amplitude',
                  parameters: const {'screen': 'home'},
                ),
                child: const Text('track'),
              ),
              FilledButton.tonal(
                onPressed: () => _demoHandledException(logger),
                child: const Text('handle'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Tools'),
          OutlinedButton.icon(
            onPressed: () => _openJsonViewer(context),
            icon: const Icon(Icons.data_object),
            label: const Text('Open JSON viewer'),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Drive the panel from code'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => ISpect.read(context).toggleISpect(),
                icon: const Icon(Icons.visibility),
                label: const Text('Toggle panel'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ISpect.read(context).togglePerformanceTracking(),
                icon: const Icon(Icons.speed),
                label: const Text('Toggle FPS overlay'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final scope = ISpect.read(context);
                  final next = scope.options.locale.languageCode == 'en'
                      ? const Locale('ru')
                      : const Locale('en');
                  scope.options = scope.options.copyWith(locale: next);
                },
                icon: const Icon(Icons.translate),
                label: const Text('Switch ISpect locale'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Inside the panel'),
          const Text(
            'Tap the floating ISpect button to open the panel:\n'
            '• Logs — filter, search, export, import, share.\n'
            '• HTTP composer (api icon) — replay or craft a request; the '
            '"attach file" control appears because onPickComposerFile is set.\n'
            '• Performance, widget inspector, color picker.',
          ),
          // Other logger methods: verbose / provider / print / log / logData.
        ],
      ),
    );
  }

  void _demoHandledException(ISpectLogger logger) {
    try {
      throw const FormatException('Malformed payload');
    } catch (e, st) {
      logger.handle(exception: e, stackTrace: st, message: 'Parse failed');
    }
  }

  void _openJsonViewer(BuildContext context) {
    const sample = <String, dynamic>{
      'user': {
        'id': 42,
        'name': 'Ada Lovelace',
        'roles': ['admin', 'editor'],
        'active': true,
      },
      'orders': [
        {'id': 'A-1', 'total': 19.99},
        {'id': 'A-2', 'total': 4.50},
      ],
      'meta': {
        'version': '5.2.0',
        'nested': {
          'deep': {'value': null}
        }
      },
    };
    const JsonScreen(data: sample).push(context);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
