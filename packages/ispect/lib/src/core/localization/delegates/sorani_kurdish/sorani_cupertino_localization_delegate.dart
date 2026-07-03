import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

import 'package:ispect/src/core/localization/delegates/kurdish_date_data.dart';

class SoraniCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SoraniCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    final localeName = intl.Intl.canonicalizedLocale(locale.toString());
    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: kurdishCupertinoLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(soraniDateSymbols),
    );

    return SynchronousFuture<CupertinoLocalizations>(
      SoraniCupertinoLocalizations(
        localeName: localeName,
        // The `intl` library's NumberFormat class is generated from CLDR data
        // (see https://github.com/dart-lang/intl/blob/master/lib/number_symbols_data.dart).
        // Kurdish locales are not listed there, so we reuse Arabic (`ar`) digits
        // and separators for Eastern Arabic numerals.
        decimalFormat: intl.NumberFormat('#,##0.###', 'ar'),
        fullYearFormat: intl.DateFormat('y', localeName),
        dayFormat: intl.DateFormat('yMd', localeName),
        doubleDigitMinuteFormat: intl.DateFormat('yMMMd', localeName),
        mediumDateFormat: intl.DateFormat('EEE, MMM d', localeName),
        singleDigitHourFormat: intl.DateFormat('EEEE, MMMM d, y', localeName),
        singleDigitMinuteFormat: intl.DateFormat('MMMM y', localeName),
        singleDigitSecondFormat: intl.DateFormat('MMM d', localeName),
        weekdayFormat: intl.DateFormat('EEEE', localeName),
      ),
    );
  }

  @override
  bool shouldReload(SoraniCupertinoLocalizationsDelegate old) => false;
}

/// Cupertino localizations for Sorani Kurdish (`ckb`).
class SoraniCupertinoLocalizations extends GlobalCupertinoLocalizations {
  const SoraniCupertinoLocalizations({
    required super.fullYearFormat,
    required super.mediumDateFormat,
    required super.decimalFormat,
    required super.dayFormat,
    required super.doubleDigitMinuteFormat,
    required super.singleDigitHourFormat,
    required super.singleDigitMinuteFormat,
    required super.singleDigitSecondFormat,
    required super.weekdayFormat,
    super.localeName = 'ckb',
  });

  @override
  String get alertDialogLabel => 'ئاگادارکردنەوە';

  @override
  String get anteMeridiemAbbreviation => 'پ.ن';

  @override
  String get copyButtonLabel => 'کۆپی';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get modalBarrierDismissLabel => 'لادان';

  @override
  String get pasteButtonLabel => 'پەیست';

  @override
  String get postMeridiemAbbreviation => 'د.ن';

  @override
  String get selectAllButtonLabel => 'دیاریکردنی هەموو';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      SoraniCupertinoLocalizationsDelegate();

  @override
  String get datePickerDateOrderString => 'dmy';

  @override
  String get datePickerDateTimeOrderString => 'date_time_dayPeriod';

  @override
  String? get datePickerHourSemanticsLabelOther => r'$hour بە وردی';

  @override
  String? get datePickerMinuteSemanticsLabelOther => r'$minute خولەک';

  @override
  String get searchTextFieldPlaceholderLabel => 'گەڕان';

  @override
  String get tabSemanticsLabelRaw => r'تابی $tabIndex لە $tabCount';

  @override
  String? get timerPickerHourLabelOther => 'کاتژمێر';

  @override
  String? get timerPickerMinuteLabelOther => 'خولەک';

  @override
  String? get timerPickerSecondLabelOther => 'چرکە';

  @override
  String get todayLabel => 'ئەمڕۆ';

  @override
  String get noSpellCheckReplacementsLabel => 'هیچ جێگرەوەیەک نەدۆزرایەوە';

  @override
  String get lookUpButtonLabel => 'گەڕانی گشتی';

  @override
  String get menuDismissLabel => 'داخستنی لیست';

  @override
  String get searchWebButtonLabel => 'گەڕان لە وێب';

  @override
  String get shareButtonLabel => 'هاوبەشکردن';

  @override
  String get clearButtonLabel => 'سڕینەوە';

  @override
  String get backButtonLabel => 'گەڕانەوە';

  @override
  String get cancelButtonLabel => 'هەڵوەشاندنەوە';

  @override
  String get collapsedHint => 'کۆکراوەتەوە';

  @override
  String get expandedHint => 'فراوانکراوە';

  @override
  String get expansionTileCollapsedHint => 'دووجار کلیک بکە بۆ فراوانکردن';

  @override
  String get expansionTileCollapsedTapHint =>
      'بۆ وردەکاری زیاتر فراوان بکە';

  @override
  String get expansionTileExpandedHint => 'دووجار کلیک بکە بۆ داخستن';

  @override
  String get expansionTileExpandedTapHint => 'دابخە';
}
