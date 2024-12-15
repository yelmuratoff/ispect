// import 'package:feedback_plus/feedback_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ispect/ispect.dart';

final class ISpectLocalizations {
  static List<LocalizationsDelegate<Object>> localizationDelegates(
    List<LocalizationsDelegate<Object>> appDelegates,
  ) {
    final localizationList = [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      ISpectGeneratedLocalization.delegate,
      ...appDelegates,
    ];
    return localizationList;
  }
}
