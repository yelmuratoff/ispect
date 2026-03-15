import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

final class ISpectLocalizations {
  static List<LocalizationsDelegate<Object>> delegates({
    List<LocalizationsDelegate<Object>> delegates = const [],
  }) {
    if (!kISpectEnabled) {
      return [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...delegates,
      ];
    }

    final localizationList = [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      ISpectGeneratedLocalization.delegate,
      ...delegates,
    ];
    return localizationList;
  }
}
