import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'ispect_localizations_en.dart';
import 'ispect_localizations_kk.dart';
import 'ispect_localizations_ru.dart';
import 'ispect_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ISpectDeviceLocalization
/// returned by `ISpectDeviceLocalization.of(context)`.
///
/// Applications need to include `ISpectDeviceLocalization.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/ispect_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ISpectDeviceLocalization.localizationsDelegates,
///   supportedLocales: ISpectDeviceLocalization.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ISpectDeviceLocalization.supportedLocales
/// property.
abstract class ISpectDeviceLocalization {
  ISpectDeviceLocalization(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ISpectDeviceLocalization? of(BuildContext context) {
    return Localizations.of<ISpectDeviceLocalization>(
        context, ISpectDeviceLocalization);
  }

  static const LocalizationsDelegate<ISpectDeviceLocalization> delegate =
      _ISpectDeviceLocalizationDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size: {size}'**
  String cacheSize(Object size);

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @appData.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get appData;

  /// No description provided for @totalFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Total files count: {count}'**
  String totalFilesCount(Object count);
}

class _ISpectDeviceLocalizationDelegate
    extends LocalizationsDelegate<ISpectDeviceLocalization> {
  const _ISpectDeviceLocalizationDelegate();

  @override
  Future<ISpectDeviceLocalization> load(Locale locale) {
    return SynchronousFuture<ISpectDeviceLocalization>(
        lookupISpectDeviceLocalization(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ISpectDeviceLocalizationDelegate old) => false;
}

ISpectDeviceLocalization lookupISpectDeviceLocalization(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ISpectDeviceLocalizationEn();
    case 'kk':
      return ISpectDeviceLocalizationKk();
    case 'ru':
      return ISpectDeviceLocalizationRu();
    case 'zh':
      return ISpectDeviceLocalizationZh();
  }

  throw FlutterError(
      'ISpectDeviceLocalization.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
