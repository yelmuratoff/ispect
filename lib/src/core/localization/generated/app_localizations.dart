import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @change_theme.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get change_theme;

  /// No description provided for @talker_type_debug.
  ///
  /// In en, this message translates to:
  /// **'Verbose & debug'**
  String get talker_type_debug;

  /// No description provided for @talker_type_debug_count.
  ///
  /// In en, this message translates to:
  /// **'Verbose and debug logs count: {text}'**
  String talker_type_debug_count(Object text);

  /// No description provided for @talker_type_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get talker_type_good;

  /// No description provided for @talker_type_good_count.
  ///
  /// In en, this message translates to:
  /// **'Good logs count: {text}'**
  String talker_type_good_count(Object text);

  /// No description provided for @talker_type_provider.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get talker_type_provider;

  /// No description provided for @talker_type_provider_count.
  ///
  /// In en, this message translates to:
  /// **'Provider logs count: {text}'**
  String talker_type_provider_count(Object text);

  /// No description provided for @talker_type_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get talker_type_info;

  /// No description provided for @talker_type_info_count.
  ///
  /// In en, this message translates to:
  /// **'Info logs count: {text}'**
  String talker_type_info_count(Object text);

  /// No description provided for @talker_type_warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get talker_type_warnings;

  /// No description provided for @talker_type_warnings_count.
  ///
  /// In en, this message translates to:
  /// **'Warning logs count: {text}'**
  String talker_type_warnings_count(Object text);

  /// No description provided for @talker_type_exceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get talker_type_exceptions;

  /// No description provided for @talker_type_exceptions_count.
  ///
  /// In en, this message translates to:
  /// **'Exception logs count: {text}'**
  String talker_type_exceptions_count(Object text);

  /// No description provided for @talker_type_errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get talker_type_errors;

  /// No description provided for @talker_type_errors_count.
  ///
  /// In en, this message translates to:
  /// **'Error logs count: {text}'**
  String talker_type_errors_count(Object text);

  /// No description provided for @talker_type_http.
  ///
  /// In en, this message translates to:
  /// **'HTTP requests'**
  String get talker_type_http;

  /// No description provided for @talker_http_requests_count.
  ///
  /// In en, this message translates to:
  /// **'HTTP request logs count: {text}'**
  String talker_http_requests_count(Object text);

  /// No description provided for @talker_http_responses_count.
  ///
  /// In en, this message translates to:
  /// **'HTTP response logs count: {text}'**
  String talker_http_responses_count(Object text);

  /// No description provided for @talker_http_failues_count.
  ///
  /// In en, this message translates to:
  /// **'HTTP failure logs count: {text}'**
  String talker_http_failues_count(Object text);

  /// No description provided for @talker_type_bloc.
  ///
  /// In en, this message translates to:
  /// **'BLoC'**
  String get talker_type_bloc;

  /// No description provided for @talker_bloc_transition_count.
  ///
  /// In en, this message translates to:
  /// **'BLoC transitions count: {text}'**
  String talker_bloc_transition_count(Object text);

  /// No description provided for @talker_bloc_events_count.
  ///
  /// In en, this message translates to:
  /// **'BLoC events count: {text}'**
  String talker_bloc_events_count(Object text);

  /// No description provided for @talker_bloc_close_count.
  ///
  /// In en, this message translates to:
  /// **'BLoC closes count: {text}'**
  String talker_bloc_close_count(Object text);

  /// No description provided for @talker_bloc_create_count.
  ///
  /// In en, this message translates to:
  /// **'BLoC creates count: {text}'**
  String talker_bloc_create_count(Object text);

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @reverse_logs.
  ///
  /// In en, this message translates to:
  /// **'Reverse logs'**
  String get reverse_logs;

  /// No description provided for @copy_all_logs.
  ///
  /// In en, this message translates to:
  /// **'Copy all logs'**
  String get copy_all_logs;

  /// No description provided for @collapse_logs.
  ///
  /// In en, this message translates to:
  /// **'Collapse logs'**
  String get collapse_logs;

  /// No description provided for @expand_logs.
  ///
  /// In en, this message translates to:
  /// **'Expand logs'**
  String get expand_logs;

  /// No description provided for @clean_history.
  ///
  /// In en, this message translates to:
  /// **'Clean history'**
  String get clean_history;

  /// No description provided for @share_logs_file.
  ///
  /// In en, this message translates to:
  /// **'Share logs file'**
  String get share_logs_file;

  /// No description provided for @log_item_copied.
  ///
  /// In en, this message translates to:
  /// **'Log item is copied in clipboard'**
  String get log_item_copied;

  /// No description provided for @basic_settings.
  ///
  /// In en, this message translates to:
  /// **'Basic settings'**
  String get basic_settings;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @use_console_logs.
  ///
  /// In en, this message translates to:
  /// **'Use console logs'**
  String get use_console_logs;

  /// No description provided for @use_history.
  ///
  /// In en, this message translates to:
  /// **'Use history'**
  String get use_history;

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

  /// No description provided for @all_logs_copied.
  ///
  /// In en, this message translates to:
  /// **'All logs copied in buffer'**
  String get all_logs_copied;

  /// No description provided for @page_not_found.
  ///
  /// In en, this message translates to:
  /// **'Oops, the page on this path'**
  String get page_not_found;

  /// No description provided for @not_found.
  ///
  /// In en, this message translates to:
  /// **'not found'**
  String get not_found;

  /// No description provided for @back_to_home.
  ///
  /// In en, this message translates to:
  /// **'Go back to the main page'**
  String get back_to_home;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get fix;

  /// No description provided for @clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clear_cache;

  /// No description provided for @cache_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cache_cleared;

  /// No description provided for @error_cache_clearing.
  ///
  /// In en, this message translates to:
  /// **'Error on clearing cache'**
  String get error_cache_clearing;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get app_version;

  /// No description provided for @build_version.
  ///
  /// In en, this message translates to:
  /// **'Build version'**
  String get build_version;

  /// No description provided for @change_environment.
  ///
  /// In en, this message translates to:
  /// **'Change current environment'**
  String get change_environment;

  /// No description provided for @go_to_logger.
  ///
  /// In en, this message translates to:
  /// **'Go to logger'**
  String get go_to_logger;

  /// No description provided for @environment_tap_number.
  ///
  /// In en, this message translates to:
  /// **'To open the dialog, it remains: {number}'**
  String environment_tap_number(Object number);

  /// No description provided for @counter_times_text.
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times: {number}'**
  String counter_times_text(Object number);

  /// No description provided for @performance_tracker.
  ///
  /// In en, this message translates to:
  /// **'Performance tracking'**
  String get performance_tracker;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @initialization_failed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed'**
  String get initialization_failed;

  /// No description provided for @error_type.
  ///
  /// In en, this message translates to:
  /// **'Error type'**
  String get error_type;

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

  /// No description provided for @you_already_in_logger.
  ///
  /// In en, this message translates to:
  /// **'You are already in the logger page'**
  String get you_already_in_logger;

  /// No description provided for @turn_on_inspector.
  ///
  /// In en, this message translates to:
  /// **'Turn on inspector'**
  String get turn_on_inspector;

  /// No description provided for @turn_off_inspector.
  ///
  /// In en, this message translates to:
  /// **'Turn off inspector'**
  String get turn_off_inspector;

  /// No description provided for @view_and_manage_data.
  ///
  /// In en, this message translates to:
  /// **'Viewing and managing application data'**
  String get view_and_manage_data;

  /// No description provided for @app_data.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get app_data;

  /// No description provided for @total_files_count.
  ///
  /// In en, this message translates to:
  /// **'Total files count: {number}'**
  String total_files_count(Object number);

  /// No description provided for @app_info.
  ///
  /// In en, this message translates to:
  /// **'Check device info & package info'**
  String get app_info;

  /// No description provided for @copied_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied_to_clipboard;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
