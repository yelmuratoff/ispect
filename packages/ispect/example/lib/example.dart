import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ispect/ispect.dart';

void main() {
  final ISpectify iSpectify = ISpectifyFlutter.init(
    options: ISpectifyOptions(
      useConsoleLogs: true,
      titles: <String, String>{
        ISpectifyLogType.critical.key: 'critical',
        ISpectifyLogType.warning.key: 'warning',
        ISpectifyLogType.verbose.key: 'verbose',
        ISpectifyLogType.info.key: 'info',
        ISpectifyLogType.debug.key: 'debug',
        ISpectifyLogType.error.key: 'error',
        ISpectifyLogType.exception.key: 'exception',
        ISpectifyLogType.httpError.key: 'http-error',
        ISpectifyLogType.httpRequest.key: 'http-request',
        ISpectifyLogType.httpResponse.key: 'http-response',
        ISpectifyLogType.route.key: 'route',
      },
    ),
  );

  ISpect.run(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(MyApp());
    },
    iSpectify: iSpectify,
  );
}

class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('zh');

  Locale get currentLocale => _currentLocale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  void setLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) return;
    _currentLocale = locale;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final NavigatorObserver _observer = ISpectNavigatorObserver();
  final DraggablePanelController _controller = DraggablePanelController();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            locale: localeProvider.currentLocale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              ISpectGeneratedLocalization.delegate,
            ],
            navigatorObservers: [_observer],
            home: MyHomePage(),
            builder: (context, child) {
              return ISpectBuilder(
                isISpectEnabled: !kReleaseMode,
                options: ISpectOptions(
                  panelButtons: [
                    (
                      icon: Icons.close,
                      label: 'Close',
                      onTap: (panelContext) {
                        // ISpect.read(panelContext).toggleISpect();
                        _controller.toggle(panelContext);
                      },
                    ),
                  ],
                ),
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('iSpect Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                ISpect.read(context).toggleISpect();
                ISpect.info('Button Pressed');
              },
              child: const Text('Log Message'),
            ),
            const SizedBox(height: 20),
            Text(
                'Current Locale: ${localeProvider.currentLocale.languageCode}'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => localeProvider.setLocale(const Locale('en')),
              child: const Text('Switch to English'),
            ),
            ElevatedButton(
              onPressed: () => localeProvider.setLocale(const Locale('zh')),
              child: const Text('Switch to Chinese'),
            ),
          ],
        ),
      ),
    );
  }
}
