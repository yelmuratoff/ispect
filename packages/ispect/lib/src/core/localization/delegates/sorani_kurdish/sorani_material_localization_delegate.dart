import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

import 'package:ispect/src/core/localization/delegates/kurdish_date_data.dart';

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    const localeName = 'ckb';

    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: kurdishMaterialLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(soraniDateSymbols),
    );
    return SynchronousFuture<MaterialLocalizations>(
      SoraniMaterialLocalizations(
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

class SoraniMaterialLocalizations extends GlobalMaterialLocalizations {
  const SoraniMaterialLocalizations({
    required super.fullYearFormat,
    required super.shortDateFormat,
    required super.compactDateFormat,
    required super.shortMonthDayFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
    super.localeName = 'ckb',
  });
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _KurdishMaterialLocalizationsDelegate();

  @override
  String get aboutListTileTitleRaw => r'دەربارەی $applicationName';

  @override
  String get alertDialogLabel => 'ئاگادارکردنەوە';

  @override
  String get anteMeridiemAbbreviation => 'پ.ن';

  @override
  String get backButtonTooltip => 'گەڕانەوە';

  @override
  String get calendarModeButtonLabel => 'گۆڕین بۆ ڕۆژژمێر';

  @override
  String get cancelButtonLabel => 'هەڵوەشاندنەوە';

  @override
  String get closeButtonLabel => 'داخستن';

  @override
  String get closeButtonTooltip => 'داخستن';

  @override
  String get collapsedIconTapHint => 'فراوانکردن';

  @override
  String get continueButtonLabel => 'بەردەوام بە';

  @override
  String get copyButtonLabel => 'کۆپی';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get dateHelpText => 'mm/dd/yyyy';

  @override
  String get dateInputLabel => 'بەروار بنووسە';

  @override
  String get dateOutOfRangeLabel => 'دەرەوەی مەودایە';

  @override
  String get datePickerHelpText => 'بەروار دیاری بکە';

  @override
  String get dateRangeEndDateSemanticLabelRaw => r'بەرواری کۆتایی $fullDate';

  @override
  String get dateRangeEndLabel => 'بەرواری کۆتایی';

  @override
  String get dateRangePickerHelpText => 'دەست نیشانکردنی مەودا';

  @override
  String get dateRangeStartDateSemanticLabelRaw =>
      r'بەرواری دەستپێکردن $fullDate';

  @override
  String get dateRangeStartLabel => 'بەرواری دەستپێکردن';

  @override
  String get dateSeparator => '/';

  @override
  String get deleteButtonTooltip => 'سڕینەوە';

  @override
  String get dialModeButtonLabel => 'گۆڕین بۆ دۆخی هەڵبژێری داواکردن';

  @override
  String get dialogLabel => 'دیالۆگ';

  @override
  String get drawerLabel => 'لیستی ڕێنیشاندەر';

  @override
  String get expandedIconTapHint => 'نوشتانەوە';

  @override
  String get hideAccountsLabel => 'شاردنەوەی ئەژمێرەکان';

  @override
  String get inputDateModeButtonLabel => 'گۆڕین بۆ نووسین';

  @override
  String get inputTimeModeButtonLabel => 'گۆڕین بۆ دۆخی تێکردنی دەق';

  @override
  String get invalidDateFormatLabel => 'فۆرماتی نادروست.';

  @override
  String get invalidDateRangeLabel => 'مەودایەکی نادروست.';

  @override
  String get invalidTimeLabel => 'کاتێکی دروست بنووسە';

  @override
  String get licensesPackageDetailTextOne => '١ مۆڵەت';

  @override
  String get licensesPackageDetailTextOther => r'$licenseCount مۆڵەت';

  @override
  String get licensesPackageDetailTextZero => 'مۆڵەت نیە';

  @override
  String get licensesPageTitle => 'مۆڵەتەکان';

  @override
  String get modalBarrierDismissLabel => 'دەرکردن';

  @override
  String get moreButtonTooltip => 'زیاتر';

  @override
  String get nextMonthTooltip => 'مانگی داهاتوو';

  @override
  String get nextPageTooltip => 'لاپەڕەی داهاتوو';

  @override
  String get okButtonLabel => 'باشە';

  @override
  String get openAppDrawerTooltip => 'کردنەوەی لیستی ڕێنیشاندەر';

  @override
  String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow لە $rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw =>
      r'$firstRow–$lastRow تا $rowCount';

  @override
  String get pasteButtonLabel => 'پەیست';

  @override
  String get popupMenuLabel => 'لیستی دەرکەوتە';

  @override
  String get postMeridiemAbbreviation => 'د.ن';

  @override
  String get previousMonthTooltip => 'مانگی پێشوو';

  @override
  String get previousPageTooltip => 'لاپەڕەی پێشوو';

  @override
  String get refreshIndicatorSemanticLabel => 'نوێکردنەوە';

  @override
  String? get remainingTextFieldCharacterCountFew => null;

  @override
  List<String> get narrowWeekdays => ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'];

  @override
  String? get remainingTextFieldCharacterCountMany => null;

  @override
  String get remainingTextFieldCharacterCountOne => '١ پیت ماوە';

  @override
  String get remainingTextFieldCharacterCountOther =>
      r'$remainingCount پیتەکان ماون';

  @override
  String? get remainingTextFieldCharacterCountTwo => null;

  @override
  String get remainingTextFieldCharacterCountZero => 'هیچ پیتێک نەماوەتەوە';

  @override
  String get reorderItemDown => 'بڕۆ خوارەوە';

  @override
  String get reorderItemLeft => 'بڕۆ لای چەپ';

  @override
  String get reorderItemRight => 'بڕۆ لای راست';

  @override
  String get reorderItemToEnd => 'بڕۆ کۆتایی';

  @override
  String get reorderItemToStart => 'بڕۆ سەرەتا';

  @override
  String get reorderItemUp => 'بڕۆ سەرەوە';

  @override
  String get rowsPerPageTitle => 'ڕیزەکان بۆ هەر پەڕەیەک:';

  @override
  String get saveButtonLabel => 'هەڵگرتن';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.tall;

  @override
  String get searchFieldLabel => 'گەڕان';

  @override
  String get selectAllButtonLabel => 'هەموو هەڵبژێرە';

  @override
  String get selectYearSemanticsLabel => 'ساڵ هەڵبژێرە';

  @override
  String? get selectedRowCountTitleFew => null;

  @override
  String? get selectedRowCountTitleMany => null;

  @override
  String get selectedRowCountTitleOne => '١ دانە هەڵبژێردرا';

  @override
  String get selectedRowCountTitleOther => r'$selectedRowCount هەڵبژێردراو';

  @override
  String? get selectedRowCountTitleTwo => null;

  @override
  String get selectedRowCountTitleZero => 'هیچ هەڵنەبژێراوە';

  @override
  String get showAccountsLabel => 'پیشاندانی ئەژمێرەکان';

  @override
  String get showMenuTooltip => 'پیشاندانی پێڕست';

  @override
  String get signedInLabel => 'چوونە ژوورەوە';

  @override
  String get tabLabelRaw => r'خشتەبەندی $tabIndex لە $tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;

  @override
  String get timePickerDialHelpText => 'کات هەڵبژێرە';

  @override
  String get timePickerHourLabel => 'کاتژمێر';

  @override
  String get timePickerHourModeAnnouncement => 'کاتژمێر هەڵبژێرە';

  @override
  String get timePickerInputHelpText => 'کات بنووسە';

  @override
  String get timePickerMinuteLabel => 'خولەک';

  @override
  String get timePickerMinuteModeAnnouncement => 'خولەک هەڵبژێرە';

  @override
  String get unspecifiedDate => 'بەروار';

  @override
  String get unspecifiedDateRange => 'مەودای بەروار';

  @override
  String get viewLicensesButtonLabel => 'پیشاندانی مۆڵەتەکان';

  @override
  String get firstPageTooltip => 'لاپه‌ڕه‌ی سه‌ره‌تا';

  @override
  String get lastPageTooltip => 'دوایین لاپه‌ڕه‌';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'AltGr';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyChannelDown => 'کەناڵی داهاتوو';

  @override
  String get keyboardKeyChannelUp => 'کەناڵی پێشوو';

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
  String get keyboardKeyNumpadAdd => 'نیشانەی +';

  @override
  String get keyboardKeyNumpadComma => 'فاریزە';

  @override
  String get keyboardKeyNumpadDecimal => 'نیشانەی .';

  @override
  String get keyboardKeyNumpadDivide => 'نیشانەی /';

  @override
  String get keyboardKeyNumpadEnter => 'Enter';

  @override
  String get keyboardKeyNumpadEqual => 'نیشانەی =';

  @override
  String get keyboardKeyNumpadMultiply => 'نیشانەی *';

  @override
  String get keyboardKeyNumpadParenLeft => 'کۆسەی چەپ';

  @override
  String get keyboardKeyNumpadParenRight => 'کۆسەی ڕاست';

  @override
  String get keyboardKeyNumpadSubtract => 'نیشانەی -';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeyPower => 'دوگمەی کارکردن';

  @override
  String get keyboardKeyPowerOff => 'دوگمەی کوژاندنەوە';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  String get keyboardKeyRomaji => 'Romaji';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeySelect => 'دوگمەی هەڵبژاردن';

  @override
  String get keyboardKeySpace => 'بۆشایی';

  String get keyboardKeyZenkaku => 'Zenkaku';

  String get keyboardKeyZenkakuHankaku => 'Zenkaku Hankaku';

  @override
  String get menuBarMenuLabel => 'لیستی شریتی مێنیو';

  @override
  String get bottomSheetLabel => 'کارتی خوارەوە';

  @override
  String get currentDateLabel => 'بەرواری ئەمڕۆ';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get scrimLabel => 'پەردە';

  @override
  String get scrimOnTapHintRaw => r'داخستنی "$modalRouteContentName"';

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

  @override
  String get scanTextButtonLabel => 'دەق بە سکانەر بخوێنەوە';

  @override
  String get lookUpButtonLabel => 'گەڕانی گشتی';

  @override
  String get menuDismissLabel => 'داخستنی لیست';

  @override
  String get searchWebButtonLabel => 'گەڕان لە وێب';

  @override
  String get shareButtonLabel => 'هاوبەشکردن';

  @override
  String get clearButtonTooltip => 'سڕینەوەی دەق';

  @override
  String get selectedDateLabel => 'بەرواری هەڵبژێردراو';
}
