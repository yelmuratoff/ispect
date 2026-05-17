import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Wraps [child] in the minimal shell required for ISpect widgets:
/// [ISpectScopeController] (provides `context.ispectTheme`) and
/// [MaterialApp] with ISpect localization delegates.
Widget appShell(Widget child) => ISpectScopeController(
      model: ISpectScopeModel(isISpectEnabled: true),
      child: MaterialApp(
        localizationsDelegates: ISpectLocalization.localizationDelegates,
        supportedLocales: ISpectLocalization.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
