import 'package:flutter/material.dart';
import 'package:ispect/src/core/localization/delegates/krmanji_kurdish/krmanji_kurdish.dart';
import 'package:ispect/src/core/localization/delegates/sorani_kurdish/sorani_kurdish.dart';

/// Kurdish localization delegates for Sorani (`ckb`) and Kurmanji (`ku`).
abstract final class ISpectKurdishLocalizations {
  static const List<LocalizationsDelegate<Object>> delegates = [
    SoraniMaterialLocalizations.delegate,
    SoraniCupertinoLocalizations.delegate,
    SoraniWidgetLocalizations.delegate,
    KrmanjiMaterialLocalizations.delegate,
    KrmanjiCupertinoLocalizations.delegate,
    KrmanjiWidgetLocalizations.delegate,
  ];
}
