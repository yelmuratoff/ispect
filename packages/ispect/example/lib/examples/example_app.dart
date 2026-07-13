import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

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
