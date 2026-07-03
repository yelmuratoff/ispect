import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async =>
      SynchronousFuture<WidgetsLocalizations>(
        KrmanjiWidgetLocalizations(),
      );

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}

class KrmanjiWidgetLocalizations extends WidgetsLocalizations {
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _KurdishMaterialLocalizationsDelegate();

  @override
  TextDirection get textDirection => TextDirection.rtl;

  @override
  String get reorderItemDown => 'بچۆ خوارێ';

  @override
  String get reorderItemLeft => 'بچۆ چەپێ';

  @override
  String get reorderItemRight => 'بچۆ ڕاستێ';

  @override
  String get reorderItemToEnd => 'بچۆ دوماهیکێ';

  @override
  String get reorderItemToStart => 'بچۆ دەستپێکێ';

  @override
  String get reorderItemUp => 'بچۆ ژۆرێ';

  @override
  String get copyButtonLabel => 'کۆپی بکە';

  @override
  String get cutButtonLabel => 'ببڕە';

  @override
  String get lookUpButtonLabel => 'لێگەریانا گشتی';

  @override
  String get pasteButtonLabel => 'پەیست بکە';

  @override
  String get searchWebButtonLabel => 'ل ئەنتەرنێتێ بگەڕی';

  @override
  String get selectAllButtonLabel => 'همیان هەلبژێره';

  @override
  String get shareButtonLabel => 'بارڤە بکە';

  @override
  String get radioButtonUnselectedLabel => 'نەهاتییە هەلبژارتن';
}
