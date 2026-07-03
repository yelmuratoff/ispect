import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    const localeName = 'ku';

    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: krmanjiMaterialLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(krmanjiDateSymbols),
    );
    return SynchronousFuture<MaterialLocalizations>(
      KrmanjiMaterialLocalizations(
        fullYearFormat: intl.DateFormat('y', localeName),
        shortDateFormat: intl.DateFormat('MM/DD/YY', localeName),
        compactDateFormat: intl.DateFormat('EEE, MMM d', localeName),
        shortMonthDayFormat: intl.DateFormat('MM/DD', localeName),
        mediumDateFormat: intl.DateFormat('EEE, MMM d', localeName),
        longDateFormat: intl.DateFormat('EEEE, MMMM d, y', localeName),
        yearMonthFormat: intl.DateFormat('MMMM y', localeName),
        // The `intl` library's NumberFormat class is generated from CLDR data
        // (see https://github.com/dart-lang/intl/blob/master/lib/number_symbols_data.dart).
        // Unfortunately, there is no way to use a locale that isn't defined in
        // this map and the only way to work around this is to use a listed
        // locale's NumberFormat symbols. So, here we use the number formats
        // for 'ar' instead.
        decimalFormat: intl.NumberFormat('#,##0.###', 'ar'),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'ar'),
      ),
    );
  }

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}

class KrmanjiMaterialLocalizations extends GlobalMaterialLocalizations {
  const KrmanjiMaterialLocalizations({
    required super.fullYearFormat,
    required super.shortDateFormat,
    required super.compactDateFormat,
    required super.shortMonthDayFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
    super.localeName = 'ku',
  });
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _KurdishMaterialLocalizationsDelegate();

  @override
  String get aboutListTileTitleRaw => r'دربارەی $applicationName';

  @override
  String get alertDialogLabel => 'ئاگادارکرن';

  @override
  String get anteMeridiemAbbreviation => 'ب.ن';

  @override
  String get backButtonTooltip => 'ڤەگەرین';

  @override
  String get calendarModeButtonLabel => 'گوهۆڕین بۆ سالنامەیێ';

  @override
  String get cancelButtonLabel => 'پەشیمانبوون';

  @override
  String get closeButtonLabel => 'بگرە';

  @override
  String get closeButtonTooltip => 'بگرە';

  @override
  String get collapsedIconTapHint => 'فراوان بکە';

  @override
  String get continueButtonLabel => 'بەردەوام بە';

  @override
  String get copyButtonLabel => 'کۆپی بکە';

  @override
  String get cutButtonLabel => 'ببڕە';

  @override
  String get dateHelpText => 'ڕۆژ/مانگ/ساڵ';

  @override
  String get dateInputLabel => 'دێروکێ بنووسە';

  @override
  String get dateOutOfRangeLabel => 'ل دەرڤەی مەودایێ یە';

  @override
  String get datePickerHelpText => 'دێروکێ هەلبژێره';

  @override
  String get dateRangeEndDateSemanticLabelRaw => r'دێروکا دوماهیکێ $fullDate';

  @override
  String get dateRangeEndLabel => 'دێروکا دوماهیکێ';

  @override
  String get dateRangePickerHelpText => 'مەودایا دێروکێ دیار بکە';

  @override
  String get dateRangeStartDateSemanticLabelRaw =>
      r'دێروکا دەستپێکێ $fullDate';

  @override
  String get dateRangeStartLabel => 'دێروکا دەستپێکێ';

  @override
  String get dateSeparator => '/';

  @override
  String get deleteButtonTooltip => 'ژێببە';

  @override
  String get dialModeButtonLabel => 'گوهۆڕین بۆ مۆدێ دەمژمێرێ';

  @override
  String get dialogLabel => 'دیالۆگ';

  @override
  String get drawerLabel => 'مێنویا ناڤینی';

  @override
  String get expandedIconTapHint => 'تەنگ بکە';

  @override
  String get hideAccountsLabel => 'حیسابان ڤەشێره';

  @override
  String get inputDateModeButtonLabel => 'گوهۆڕین بۆ نووسینێ';

  @override
  String get inputTimeModeButtonLabel => 'گوهۆڕین بۆ مۆدێ نووسینا دەمی';

  @override
  String get invalidDateFormatLabel => 'فۆرماتی نەدروست.';

  @override
  String get invalidDateRangeLabel => 'مەودایا نەدروست.';

  @override
  String get invalidTimeLabel => 'دەما دروست بنووسە';

  @override
  String get licensesPackageDetailTextOne => '١ لایسنس';

  @override
  String get licensesPackageDetailTextOther => r'$licenseCount لایسنس';

  @override
  String get licensesPackageDetailTextZero => 'چ لایسنس نینن';

  @override
  String get licensesPageTitle => 'لایسنس';

  @override
  String get modalBarrierDismissLabel => 'دەرکەڤە';

  @override
  String get moreButtonTooltip => 'زێدەتر';

  @override
  String get nextMonthTooltip => 'مانگا بهێت';

  @override
  String get nextPageTooltip => 'پەڕێ بهێت';

  @override
  String get okButtonLabel => 'باشە';

  @override
  String get openAppDrawerTooltip => 'مێنویا ناڤینی ڤەکە';

  @override
  String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow ژ $rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw =>
      r'$firstRow–$lastRow ژ نێزیکی $rowCount';

  @override
  String get pasteButtonLabel => 'پەیست بکە';

  @override
  String get popupMenuLabel => 'مێنویا دەرکەڤتی';

  @override
  String get postMeridiemAbbreviation => 'پ.ن';

  @override
  String get previousMonthTooltip => 'مانگا بەری نوکە';

  @override
  String get previousPageTooltip => 'پەڕێ بەری نوکە';

  @override
  String get refreshIndicatorSemanticLabel => 'نوو بکە';

  @override
  String? get remainingTextFieldCharacterCountFew => null;

  @override
  List<String> get narrowWeekdays => ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'];

  @override
  String? get remainingTextFieldCharacterCountMany => null;

  @override
  String get remainingTextFieldCharacterCountOne => '١ پیت مایە';

  @override
  String get remainingTextFieldCharacterCountOther =>
      r'$remainingCount پیت ماینە';

  @override
  String? get remainingTextFieldCharacterCountTwo => null;

  @override
  String get remainingTextFieldCharacterCountZero => 'چ پیت نەماینە';

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
  String get rowsPerPageTitle => 'ڕێز بۆ هەر پەڕەکێ:';

  @override
  String get saveButtonLabel => 'پاشەکەفت بکە';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.tall;

  @override
  String get searchFieldLabel => 'لێگەریان';

  @override
  String get selectAllButtonLabel => 'همیان هەلبژێره';

  @override
  String get selectYearSemanticsLabel => 'سالێ هەلبژێره';

  @override
  String? get selectedRowCountTitleFew => null;

  @override
  String? get selectedRowCountTitleMany => null;

  @override
  String get selectedRowCountTitleOne => '١ هاتە هەلبژارتن';

  @override
  String get selectedRowCountTitleOther => r'$selectedRowCount هاتنە هەلبژارتن';

  @override
  String? get selectedRowCountTitleTwo => null;

  @override
  String get selectedRowCountTitleZero => 'چ نەهاتینە هەلبژارتن';

  @override
  String get showAccountsLabel => 'حیسابان نیشان بدە';

  @override
  String get showMenuTooltip => 'مێنویێ نیشان بدە';

  @override
  String get signedInLabel => 'تێکەفت';

  @override
  String get tabLabelRaw => r'تابا $tabIndex ژ $tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;

  @override
  String get timePickerDialHelpText => 'دەمی هەلبژێره';

  @override
  String get timePickerHourLabel => 'دەمژمێر';

  @override
  String get timePickerHourModeAnnouncement => 'دەمژمێرێ هەلبژێره';

  @override
  String get timePickerInputHelpText => 'دەمی بنووسە';

  @override
  String get timePickerMinuteLabel => 'خولەک';

  @override
  String get timePickerMinuteModeAnnouncement => 'خولەکێ هەلبژێره';

  @override
  String get unspecifiedDate => 'دێروک';

  @override
  String get unspecifiedDateRange => 'مەودایا دێروکێ';

  @override
  String get viewLicensesButtonLabel => 'لایسنسان نیشان بدە';

  @override
  String get firstPageTooltip => 'پەڕێ دەستپێکێ';

  @override
  String get lastPageTooltip => 'پەڕێ دوماهیکێ';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'AltGr';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyChannelDown => 'کەناڵێ خوارێ';

  @override
  String get keyboardKeyChannelUp => 'کەناڵێ ژۆرێ';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyDelete => 'Del';

  String get keyboardKeyEisu => 'Eisu';

  @override
  String get keyboardKeyEject => 'Eject';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyFn => 'Fn';

  String get keyboardKeyHangulMode => 'Hangul Mode';

  String get keyboardKeyHanjaMode => 'Hanja Mode';

  String get keyboardKeyHankaku => 'Hankaku';

  String get keyboardKeyHiragana => 'Hiragana';

  String get keyboardKeyHiraganaKatakana => 'Hiragana Katakana';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  String get keyboardKeyKanaMode => 'Kana Mode';

  String get keyboardKeyKanjiMode => 'Kanji Mode';

  String get keyboardKeyKatakana => 'Katakana';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaMacOs => 'Command';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyNumpad0 => 'ژمارە ٠';

  @override
  String get keyboardKeyNumpad1 => 'ژمارە ١';

  @override
  String get keyboardKeyNumpad2 => 'ژمارە ٢';

  @override
  String get keyboardKeyNumpad3 => 'ژمارە ٣';

  @override
  String get keyboardKeyNumpad4 => 'ژمارە ٤';

  @override
  String get keyboardKeyNumpad5 => 'ژمارە ٥';

  @override
  String get keyboardKeyNumpad6 => 'ژمارە ٦';

  @override
  String get keyboardKeyNumpad7 => 'ژمارە ٧';

  @override
  String get keyboardKeyNumpad8 => 'ژمارە ٨';

  @override
  String get keyboardKeyNumpad9 => 'ژمارە ٩';

  @override
  String get keyboardKeyNumpadAdd => 'نیشانا +';

  @override
  String get keyboardKeyNumpadComma => 'فاریزە';

  @override
  String get keyboardKeyNumpadDecimal => 'نیشانا .';

  @override
  String get keyboardKeyNumpadDivide => 'نیشانا /';

  @override
  String get keyboardKeyNumpadEnter => 'Enter';

  @override
  String get keyboardKeyNumpadEqual => 'نیشانا =';

  @override
  String get keyboardKeyNumpadMultiply => 'نیشانا *';

  @override
  String get keyboardKeyNumpadParenLeft => 'کەڤانێ چەپ';

  @override
  String get keyboardKeyNumpadParenRight => 'کەڤانێ ڕاست';

  @override
  String get keyboardKeyNumpadSubtract => 'نیشانا -';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeyPower => 'دوگمەیا کارکرنێ';

  @override
  String get keyboardKeyPowerOff => 'دوگمەیا کوژاندنێ';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  String get keyboardKeyRomaji => 'Romaji';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeySelect => 'دوگمەیا هەلبژارتنێ';

  @override
  String get keyboardKeySpace => 'بۆشایی';

  String get keyboardKeyZenkaku => 'Zenkaku';

  String get keyboardKeyZenkakuHankaku => 'Zenkaku Hankaku';

  @override
  String get menuBarMenuLabel => 'لیستا شریتا مێنویا';

  @override
  String get bottomSheetLabel => 'کارتا خوارێ';

  @override
  String get currentDateLabel => 'دێروکا ئەڤڕۆ';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get scrimLabel => 'پەردە';

  @override
  String get scrimOnTapHintRaw => r'داخستنا "$modalRouteContentName"';

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

  @override
  String get scanTextButtonLabel => 'دەقی ب سکانەرێ بخوینە';

  @override
  String get lookUpButtonLabel => 'لێگەریانا گشتی';

  @override
  String get menuDismissLabel => 'داخستنا لیستی';

  @override
  String get searchWebButtonLabel => 'ل ئەنتەرنێتێ بگەڕی';

  @override
  String get shareButtonLabel => 'بارڤە بکە';

  @override
  String get clearButtonTooltip => 'پاقژکرنا دەقی';

  @override
  String get selectedDateLabel => 'دێروکا هەلبژارتی';
}

const krmanjiDateSymbols = {
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

const krmanjiMaterialLocaleDatePatterns = {
  'd': 'd', // DAY
  'E': 'ccc', // ABBR_WEEKDAY
  'EEEE': 'cccc', // WEEKDAY
  'LLL': 'LLL', // ABBR_STANDALONE_MONTH
  'LLLL': 'LLLL', // STANDALONE_MONTH
  'M': 'L', // NUM_MONTH
  'Md': 'd/‏M', // NUM_MONTH_DAY
  'MEd': 'EEE، d/M', // NUM_MONTH_WEEKDAY_DAY
  'MMM': 'LLL', // ABBR_MONTH
  'MMMd': 'd MMM', // ABBR_MONTH_DAY
  'MMMEd': 'EEE، d MMM', // ABBR_MONTH_WEEKDAY_DAY
  'MMMM': 'LLLL', // MONTH
  'MMMMd': 'd MMMM', // MONTH_DAY
  'MMMMEEEEd': 'EEEE، d MMMM', // MONTH_WEEKDAY_DAY
  'QQQ': 'QQQ', // ABBR_QUARTER
  'QQQQ': 'QQQQ', // QUARTER
  'y': 'y', // YEAR
  'yM': 'M‏/y', // YEAR_NUM_MONTH
  'yMd': 'd‏/M‏/y', // YEAR_NUM_MONTH_DAY
  'yMEd': 'EEE، d/‏M/‏y', // YEAR_NUM_MONTH_WEEKDAY_DAY
  'yMMM': 'MMM y', // YEAR_ABBR_MONTH
  'yMMMd': 'd MMM y', // YEAR_ABBR_MONTH_DAY
  'yMMMEd': 'EEE، d MMM y', // YEAR_ABBR_MONTH_WEEKDAY_DAY
  'yMMMM': 'MMMM y', // YEAR_MONTH
  'yMMMMd': 'd MMMM y', // YEAR_MONTH_DAY
  'yMMMMEEEEd': 'EEEE، d MMMM y', // YEAR_MONTH_WEEKDAY_DAY
  'yQQQ': 'QQQ y', // YEAR_ABBR_QUARTER
  'yQQQQ': 'QQQQ y', // YEAR_QUARTER
  'H': 'HH', // HOUR24
  'Hm': 'HH:mm', // HOUR24_MINUTE
  'Hms': 'HH:mm:ss', // HOUR24_MINUTE_SECOND
  'j': 'h a', // HOUR
  'jm': 'h:mm a', // HOUR_MINUTE
  'jms': 'h:mm:ss a', // HOUR_MINUTE_SECOND
  'jmv': 'h:mm a v', // HOUR_MINUTE_GENERIC_TZ
  'jmz': 'h:mm a z', // HOUR_MINUTETZ
  'jz': 'h a z', // HOURGENERIC_TZ
  'm': 'm', // MINUTE
  'ms': 'mm:ss', // MINUTE_SECOND
  's': 's', // SECOND
  'v': 'v', // ABBR_GENERIC_TZ
  'z': 'z', // ABBR_SPECIFIC_TZ
  'zzzz': 'zzzz', // SPECIFIC_TZ
  'ZZZZ': 'ZZZZ', // ABBR_UTC_TZ
};
