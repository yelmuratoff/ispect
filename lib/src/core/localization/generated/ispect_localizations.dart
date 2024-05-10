import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'package:ispect/src/core/localization/generated/ispect_localizations_en.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_ru.dart';

/// Callers can lookup localized strings with an instance of ISpectGeneratedLocalization
/// returned by `ISpectGeneratedLocalization.of(context)`.
///
/// Applications need to include `ISpectGeneratedLocalization.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/ispect_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ISpectGeneratedLocalization.localizationsDelegates,
///   supportedLocales: ISpectGeneratedLocalization.supportedLocales,
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
/// be consistent with the languages listed in the ISpectGeneratedLocalization.supportedLocales
/// property.
abstract class ISpectGeneratedLocalization {
  ISpectGeneratedLocalization(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ISpectGeneratedLocalization? of(BuildContext context) =>
      Localizations.of<ISpectGeneratedLocalization>(
        context,
        ISpectGeneratedLocalization,
      );

  static const LocalizationsDelegate<ISpectGeneratedLocalization> delegate =
      _ISpectGeneratedLocalizationDelegate();

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
    Locale('ru'),
  ];

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get changeTheme;

  /// No description provided for @talkerTypeDebug.
  ///
  /// In en, this message translates to:
  /// **'Verbose & debug'**
  String get talkerTypeDebug;

  /// No description provided for @talkerTypeDebugCount.
  ///
  /// In en, this message translates to:
  /// **'Verbose and debug logs count: {text}'**
  String talkerTypeDebugCount(Object text);

  /// No description provided for @talkerTypeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get talkerTypeGood;

  /// No description provided for @talkerTypeGoodCount.
  ///
  /// In en, this message translates to:
  /// **'Good logs count: {text}'**
  String talkerTypeGoodCount(Object text);

  /// No description provided for @talkerTypeProvider.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get talkerTypeProvider;

  /// No description provided for @talkerTypeProviderCount.
  ///
  /// In en, this message translates to:
  /// **'Provider logs count: {text}'**
  String talkerTypeProviderCount(Object text);

  /// No description provided for @talkerTypeInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get talkerTypeInfo;

  /// No description provided for @talkerTypeInfoCount.
  ///
  /// In en, this message translates to:
  /// **'Info logs count: {text}'**
  String talkerTypeInfoCount(Object text);

  /// No description provided for @talkerTypeWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get talkerTypeWarnings;

  /// No description provided for @talkerTypeWarningsCount.
  ///
  /// In en, this message translates to:
  /// **'Warning logs count: {text}'**
  String talkerTypeWarningsCount(Object text);

  /// No description provided for @talkerTypeExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get talkerTypeExceptions;

  /// No description provided for @talkerTypeExceptionsCount.
  ///
  /// In en, this message translates to:
  /// **'Exception logs count: {text}'**
  String talkerTypeExceptionsCount(Object text);

  /// No description provided for @talkerTypeErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get talkerTypeErrors;

  /// No description provided for @talkerTypeErrorsCount.
  ///
  /// In en, this message translates to:
  /// **'Error logs count: {text}'**
  String talkerTypeErrorsCount(Object text);

  /// No description provided for @talkerTypeHttp.
  ///
  /// In en, this message translates to:
  /// **'HTTP requests'**
  String get talkerTypeHttp;

  /// No description provided for @talkerHttpRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'HTTP request logs count: {text}'**
  String talkerHttpRequestsCount(Object text);

  /// No description provided for @talkerHttpResponsesCount.
  ///
  /// In en, this message translates to:
  /// **'HTTP response logs count: {text}'**
  String talkerHttpResponsesCount(Object text);

  /// No description provided for @talkerHttpFailuresCount.
  ///
  /// In en, this message translates to:
  /// **'HTTP failure logs count: {text}'**
  String talkerHttpFailuresCount(Object text);

  /// No description provided for @talkerTypeBloc.
  ///
  /// In en, this message translates to:
  /// **'BLoC'**
  String get talkerTypeBloc;

  /// No description provided for @talkerBlocTransitionCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC transitions count: {text}'**
  String talkerBlocTransitionCount(Object text);

  /// No description provided for @talkerBlocEventsCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC events count: {text}'**
  String talkerBlocEventsCount(Object text);

  /// No description provided for @talkerBlocClosesCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC closes count: {text}'**
  String talkerBlocClosesCount(Object text);

  /// No description provided for @talkerBlocCreatesCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC creates count: {text}'**
  String talkerBlocCreatesCount(Object text);

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @reverseLogs.
  ///
  /// In en, this message translates to:
  /// **'Reverse logs'**
  String get reverseLogs;

  /// No description provided for @copyAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy all logs'**
  String get copyAllLogs;

  /// No description provided for @collapseLogs.
  ///
  /// In en, this message translates to:
  /// **'Collapse logs'**
  String get collapseLogs;

  /// No description provided for @expandLogs.
  ///
  /// In en, this message translates to:
  /// **'Expand logs'**
  String get expandLogs;

  /// No description provided for @cleanHistory.
  ///
  /// In en, this message translates to:
  /// **'Clean history'**
  String get cleanHistory;

  /// No description provided for @shareLogsFile.
  ///
  /// In en, this message translates to:
  /// **'Share logs file'**
  String get shareLogsFile;

  /// No description provided for @logItemCopied.
  ///
  /// In en, this message translates to:
  /// **'Log item is copied in clipboard'**
  String get logItemCopied;

  /// No description provided for @basicSettings.
  ///
  /// In en, this message translates to:
  /// **'Basic settings'**
  String get basicSettings;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @useConsoleLogs.
  ///
  /// In en, this message translates to:
  /// **'Use console logs'**
  String get useConsoleLogs;

  /// No description provided for @useHistory.
  ///
  /// In en, this message translates to:
  /// **'Use history'**
  String get useHistory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @allLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'All logs copied in buffer'**
  String get allLogsCopied;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Oops, the page on this path'**
  String get pageNotFound;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'not found'**
  String get notFound;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Go back to the main page'**
  String get backToHome;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get fix;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @errorCacheClearing.
  ///
  /// In en, this message translates to:
  /// **'Error on clearing cache'**
  String get errorCacheClearing;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @buildVersion.
  ///
  /// In en, this message translates to:
  /// **'Build version'**
  String get buildVersion;

  /// No description provided for @changeEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Change current environment'**
  String get changeEnvironment;

  /// No description provided for @goToLogger.
  ///
  /// In en, this message translates to:
  /// **'Go to logger'**
  String get goToLogger;

  /// No description provided for @environmentTapNumber.
  ///
  /// In en, this message translates to:
  /// **'To open the dialog, it remains: {number}'**
  String environmentTapNumber(Object number);

  /// No description provided for @counterTimesText.
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times: {number}'**
  String counterTimesText(Object number);

  /// No description provided for @performanceTracker.
  ///
  /// In en, this message translates to:
  /// **'Performance tracking'**
  String get performanceTracker;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed'**
  String get initializationFailed;

  /// No description provided for @errorType.
  ///
  /// In en, this message translates to:
  /// **'Error type'**
  String get errorType;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @youAlreadyInLogger.
  ///
  /// In en, this message translates to:
  /// **'You are already in the logger page'**
  String get youAlreadyInLogger;

  /// No description provided for @turnOnInspector.
  ///
  /// In en, this message translates to:
  /// **'Turn on inspector'**
  String get turnOnInspector;

  /// No description provided for @turnOffInspector.
  ///
  /// In en, this message translates to:
  /// **'Turn off inspector'**
  String get turnOffInspector;

  /// No description provided for @viewAndManageData.
  ///
  /// In en, this message translates to:
  /// **'Viewing and managing application data'**
  String get viewAndManageData;

  /// No description provided for @appData.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get appData;

  /// No description provided for @totalFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Total files count: {number}'**
  String totalFilesCount(Object number);

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'Check device info & package info'**
  String get appInfo;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size: {size}'**
  String cacheSize(Object size);
}

class _ISpectGeneratedLocalizationDelegate
    extends LocalizationsDelegate<ISpectGeneratedLocalization> {
  const _ISpectGeneratedLocalizationDelegate();

  @override
  Future<ISpectGeneratedLocalization> load(Locale locale) =>
      SynchronousFuture<ISpectGeneratedLocalization>(
        lookupISpectGeneratedLocalization(locale),
      );

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_ISpectGeneratedLocalizationDelegate old) => false;
}

ISpectGeneratedLocalization lookupISpectGeneratedLocalization(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ISpectGeneratedLocalizationEn();
    case 'ru':
      return ISpectGeneratedLocalizationRu();
  }

  throw FlutterError(
      'ISpectGeneratedLocalization.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
