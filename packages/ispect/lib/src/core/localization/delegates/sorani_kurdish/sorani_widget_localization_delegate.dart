import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async =>
      SynchronousFuture<WidgetsLocalizations>(
        SoraniWidgetLocalizations(),
      );

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}

class SoraniWidgetLocalizations extends WidgetsLocalizations {
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _KurdishMaterialLocalizationsDelegate();

  @override
  TextDirection get textDirection => TextDirection.rtl;

  @override
  String get reorderItemDown => 'بڕۆ خوارەوە';

  @override
  String get reorderItemLeft => 'بڕۆ لای چەپ';

  @override
  String get reorderItemRight => 'بڕۆ لای ڕاست';

  @override
  String get reorderItemToEnd => 'بڕۆ کۆتایی';

  @override
  String get reorderItemToStart => 'بڕۆ سەرەتا';

  @override
  String get reorderItemUp => 'بڕۆ سەرەوە';

  @override
  String get copyButtonLabel => 'کۆپی';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get lookUpButtonLabel => 'گەڕانی گشتی';

  @override
  String get pasteButtonLabel => 'پەیست';

  @override
  String get searchWebButtonLabel => 'گەڕان لە وێب';

  @override
  String get selectAllButtonLabel => 'هەموو هەڵبژێرە';

  @override
  String get shareButtonLabel => 'هاوبەشکردن';

  @override
  String get radioButtonUnselectedLabel => 'هەڵنەبژێردراو';
}
