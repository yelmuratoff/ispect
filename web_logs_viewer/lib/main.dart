import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

import 'src/features/file_viewer/presentation/pages/file_viewer_page.dart';

final observer = ISpectNavigatorObserver();

void main() {
  ISpect.run(() => runApp(const MyApp()), logger: ISpectifyFlutter.init());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [observer],
      localizationsDelegates: ISpectLocalizations.delegates(),
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
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const FileViewerPage(title: 'ISpect File Viewer'),
      builder: (context, child) => ISpectBuilder(
        isISpectEnabled: true,
        options: ISpectOptions(observer: observer),
        child: child!,
      ),
    );
  }
}
