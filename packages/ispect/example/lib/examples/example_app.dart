import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:ispect/ispect.dart';
import 'package:material_ui/material_ui.dart';

Widget buildExampleApp({
  required String title,
  required Widget home,
  required ISpectNavigatorObserver observer,
}) =>
    MaterialApp(
      title: title,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...ISpectLocalizations.delegate(),
      ],
      navigatorObservers: ISpectNavigatorObserver.observers(observer: observer),
      builder: (_, child) => ISpectBuilder.wrap(
        child: child!,
        options: ISpectOptions(observer: observer),
      ),
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: home,
    );
