import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Wraps [child] in the minimal shell required for ISpect widgets:
/// [ISpectScopeController] (provides `context.ispectTheme`) and
/// [MaterialApp] with ISpect localization delegates.
///
/// Pass [locale] to render under a specific ISpect locale, [theme] to supply
/// custom ISpect theming such as custom log types, and [options] to configure
/// ISpect callbacks.
Widget appShell(
  Widget child, {
  Locale? locale,
  ISpectTheme? theme,
  ISpectOptions? options,
}) => ISpectScopeController(
  model: ISpectScopeModel(
    isISpectEnabled: true,
    theme: theme ?? const ISpectTheme(),
    options: options,
  ),
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: ISpectLocalization.localizationDelegates,
    supportedLocales: ISpectLocalization.supportedLocales,
    home: Scaffold(body: child),
  ),
);
