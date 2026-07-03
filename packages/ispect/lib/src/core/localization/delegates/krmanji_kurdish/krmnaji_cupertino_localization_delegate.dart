import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

const krmanjiCupertinoLocaleDatePatterns = {
  'd': 'd.',
  'E': 'ccc',
  'EEEE': 'cccc',
  'LLL': 'LLL',
  'LLLL': 'LLLL',
  'M': 'L.',
  'Md': 'd.M.',
  'MEd': 'EEE d.M.',
  'MMM': 'LLL',
  'MMMd': 'd. MMM',
  'MMMEd': 'EEE d. MMM',
  'MMMM': 'LLLL',
  'MMMMd': 'd. MMMM',
  'MMMMEEEEd': 'EEEE d. MMMM',
  'QQQ': 'QQQ',
  'QQQQ': 'QQQQ',
  'y': 'y',
  'yM': 'M.y',
  'yMd': 'd.M.y',
  'yMEd': 'EEE d.MM.y',
  'yMMM': 'MMM y',
  'yMMMd': 'd. MMM y',
  'yMMMEd': 'EEE d. MMM y',
  'yMMMM': 'MMMM y',
  'yMMMMd': 'd. MMMM y',
  'yMMMMEEEEd': 'EEEE d. MMMM y',
  'yQQQ': 'QQQ y',
  'yQQQQ': 'QQQQ y',
  'H': 'HH',
  'Hm': 'HH:mm',
  'Hms': 'HH:mm:ss',
  'j': 'HH',
  'jm': 'HH:mm',
  'jms': 'HH:mm:ss',
  'jmv': 'HH:mm v',
  'jmz': 'HH:mm z',
  'jz': 'HH z',
  'm': 'm',
  'ms': 'mm:ss',
  's': 's',
  'v': 'v',
  'z': 'z',
  'zzzz': 'zzzz',
  'ZZZZ': 'ZZZZ',
};

const krmanjiDateSymbols2 = {
  'NAME': 'ku',
  'ERAS': ['ب.ز', 'ز'],
  'ERANAMES': ['پێش زاینی', 'زاینی'],
  'NARROWMONTHS': [
    'ک.د',
    'ش',
    'ز',
    'ن',
    'م',
    'ح',
    'ت',
    'ئ',
    'ل',
    'ت.ی',
    'ت.د',
    'ک.ی',
  ],
  'STANDALONENARROWMONTHS': [
    'ک.د',
    'ش',
    'ز',
    'ن',
    'م',
    'ح',
    'ت',
    'ئ',
    'ل',
    'ت.ی',
    'ت.د',
    'ک.ی',
  ],
  'MONTHS': [
    'کانونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'مایس',
    'حوزەیران',
    'تەمموز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانونی یەکەم',
  ],
  'STANDALONEMONTHS': [
    'کانونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'مایس',
    'حوزەیران',
    'تەمموز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانونی یەکەم',
  ],
  'SHORTMONTHS': [
    'کانونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'مایس',
    'حوزەیران',
    'تەمموز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانونی یەکەم',
  ],
  'STANDALONESHORTMONTHS': [
    'کانونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'مایس',
    'حوزەیران',
    'تەمموز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانونی یەکەم',
  ],
  'WEEKDAYS': [
    'یەکشەممە',
    'دووشەممە',
    'سێشەممە',
    'چوارشەممە',
    'پێنجشەممە',
    'هەینی',
    'شەممە',
  ],
  'STANDALONEWEEKDAYS': [
    'یەکشەممە',
    'دووشەممە',
    'سێشەممە',
    'چوارشەممە',
    'پێنجشەممە',
    'هەینی',
    'شەممە',
  ],
  'SHORTWEEKDAYS': [
    'یەکشەم',
    'دووشەم',
    'سێشەم',
    'چوارشەم',
    'پێنجشەم',
    'هەینی',
    'شەممە',
  ],
  'STANDALONESHORTWEEKDAYS': [
    'یەکشەم',
    'دووشەم',
    'سێشەم',
    'چوارشەم',
    'پێنجشەم',
    'هەینی',
    'شەممە',
  ],
  'NARROWWEEKDAYS': ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'],
  'STANDALONENARROWWEEKDAYS': ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'],
  'SHORTQUARTERS': ['چ١', 'چ٢', 'چ٣', 'چ٤'],
  'QUARTERS': ['چارەکی یەکەم', 'چارەکی دووەم', 'چارەکی سێیەم', 'چارەکی چوارەم'],
  'AMPMS': ['ب.ن', 'پ.ن'],
  'DATEFORMATS': [
    'EEEE، d MMMM y',
    'd MMMM y',
    'dd‏/MM‏/y',
    'd‏/M‏/y',
  ],
  'TIMEFORMATS': [
    'h:mm:ss a zzzz',
    'h:mm:ss a z',
    'h:mm:ss a',
    'h:mm a',
  ],
  'AVAILABLEFORMATS': null,
  'DATETIMEFORMATS': [
    '{1} {0}',
    '{1} {0}',
    '{1} {0}',
    '{1} {0}',
  ],
  'ZERODIGIT': '٠',
  'FIRSTDAYOFWEEK': 5,
  'WEEKENDRANGE': [4, 5],
  'FIRSTWEEKCUTOFFDAY': 3,
};

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
      patterns: krmanjiCupertinoLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(krmanjiDateSymbols2),
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
