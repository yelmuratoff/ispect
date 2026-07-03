import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

import 'package:ispect/src/core/localization/delegates/kurdish_date_data.dart';

class KrmanjiCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KrmanjiCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    final localeName = intl.Intl.canonicalizedLocale(locale.toString());
    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: kurdishCupertinoLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(kurmanjiDateSymbols),
    );

    return SynchronousFuture<CupertinoLocalizations>(
      KrmanjiCupertinoLocalizations(
        localeName: localeName,
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
  bool shouldReload(KrmanjiCupertinoLocalizationsDelegate old) => false;
}

class KrmanjiCupertinoLocalizations extends GlobalCupertinoLocalizations {
  const KrmanjiCupertinoLocalizations({
    required super.fullYearFormat,
    required super.mediumDateFormat,
    required super.decimalFormat,
    required super.dayFormat,
    required super.doubleDigitMinuteFormat,
    required super.singleDigitHourFormat,
    required super.singleDigitMinuteFormat,
    required super.singleDigitSecondFormat,
    required super.weekdayFormat,
    super.localeName = 'ku',
  });

  @override
  String get alertDialogLabel => 'ئاگادارکردن';

  @override
  String get anteMeridiemAbbreviation => 'ب.ن';

  @override
  String get copyButtonLabel => 'کۆپی بکە';

  @override
  String get cutButtonLabel => 'ببڕە';

  @override
  String get modalBarrierDismissLabel => 'دەرکەڤە';

  @override
  String get pasteButtonLabel => 'پەیست بکە';

  @override
  String get postMeridiemAbbreviation => 'پ.ن';

  @override
  String get selectAllButtonLabel => 'همیان هەلبژێره';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      KrmanjiCupertinoLocalizationsDelegate();

  @override
  String get datePickerDateOrderString => 'dmy';

  @override
  String get datePickerDateTimeOrderString => 'date_time_dayPeriod';

  @override
  String? get datePickerHourSemanticsLabelOther => r'$hour بە وردی';

  @override
  String? get datePickerMinuteSemanticsLabelOther => r'$minute خولەک';

  @override
  String get searchTextFieldPlaceholderLabel => 'لێگەریان';

  @override
  String get tabSemanticsLabelRaw => r'تابا $tabIndex ژ $tabCount';

  @override
  String? get timerPickerHourLabelOther => 'دەمژمێر';

  @override
  String? get timerPickerMinuteLabelOther => 'خولەک';

  @override
  String? get timerPickerSecondLabelOther => 'چرکە';

  @override
  String get todayLabel => 'ئەمڕۆ';

  @override
  String get noSpellCheckReplacementsLabel => 'هیچ جێگرەوەیەک نەدۆزرایەوە';

  @override
  String get lookUpButtonLabel => 'لێگەریانا گشتی';

  @override
  String get menuDismissLabel => 'داخستنا لیستی';

  @override
  String get searchWebButtonLabel => 'ل ئەنتەرنێتێ بگەڕی';

  @override
  String get shareButtonLabel => 'بارڤە بکە';

  @override
  String get clearButtonLabel => 'پاقژ بکە';

  @override
  String get backButtonLabel => 'ڤەگەرە';

  @override
  String get cancelButtonLabel => 'پەشیمانبوون';

  @override
  String get collapsedHint => 'کۆمکری';

  @override
  String get expandedHint => 'فراوانکری';

  @override
  String get expansionTileCollapsedHint => 'دووجار کلیک بکە بۆ فراوانکرنێ';

  @override
  String get expansionTileCollapsedTapHint => 'بۆ زانیاریێن زێدەتر فراوان بکە';

  @override
  String get expansionTileExpandedHint => 'دووجار کلیک بکە بۆ داخستنێ';

  @override
  String get expansionTileExpandedTapHint => 'بگرە';
}
