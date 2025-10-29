import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:web_logs_viewer/src/core/localization/generated/app_localizations.dart';
import 'package:web_logs_viewer/src/core/services/theme_manager.dart';
import 'package:web_logs_viewer/src/features/demo/presentation/demo_screen.dart';

import 'src/features/file_viewer/presentation/pages/file_viewer_page.dart';

void main() {
  final logger = ISpectFlutter.init();
  ISpect.run(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
    logger: logger,
    onInit: () {
      Bloc.observer = ISpectBlocObserver(logger: logger);
      client.interceptors.add(ISpectHttpInterceptor(logger: logger));
      dio.interceptors.add(ISpectDioInterceptor(logger: logger));
      dummyDio.interceptors.add(ISpectDioInterceptor(logger: logger));
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final draggablePanelController = DraggablePanelController();
  final observer = ISpectNavigatorObserver();

  @override
  void dispose() {
    draggablePanelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      child: MaterialApp(
        navigatorObservers: [observer],
        localizationsDelegates: ISpectLocalizations.delegates(
          delegates: [ExampleGeneratedLocalization.delegate],
        ),
        supportedLocales: ExampleGeneratedLocalization.supportedLocales,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: const FileViewerPage(title: 'ISpect File Viewer'),
        builder: (context, child) => ISpectBuilder(
          isISpectEnabled: true,
          controller: draggablePanelController,
          options: ISpectOptions(
            observer: observer,
            panelButtons: [
              DraggablePanelButtonItem(
                icon: Icons.bug_report_outlined,
                label: 'Demo Screen',
                description: 'Open Demo Screen',
                onTap: (_) {
                  draggablePanelController.toggle(context);
                  observer.navigator?.push(
                    MaterialPageRoute(builder: (context) => DemoScreen()),
                  );
                },
              ),
            ],
          ),

          child: child!,
        ),
      ),
    );
  }
}
