// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ispect/src/core/localization/generated/intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class ISpectGeneratedLocalization {
  ISpectGeneratedLocalization();

  static ISpectGeneratedLocalization? _current;

  static ISpectGeneratedLocalization get current {
    assert(
      _current != null,
      'No instance of ISpectGeneratedLocalization was loaded. Try to initialize the ISpectGeneratedLocalization delegate before accessing ISpectGeneratedLocalization.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<ISpectGeneratedLocalization> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = ISpectGeneratedLocalization();
      ISpectGeneratedLocalization._current = instance;

      return instance;
    });
  }

  static ISpectGeneratedLocalization of(BuildContext context) {
    final instance = ISpectGeneratedLocalization.maybeOf(context);
    assert(
      instance != null,
      'No instance of ISpectGeneratedLocalization present in the widget tree. Did you add ISpectGeneratedLocalization.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static ISpectGeneratedLocalization? maybeOf(BuildContext context) =>
      Localizations.of<ISpectGeneratedLocalization>(
        context,
        ISpectGeneratedLocalization,
      );

  /// `Change theme`
  String get change_theme => Intl.message(
        'Change theme',
        name: 'change_theme',
        desc: '',
        args: [],
      );

  /// `Verbose & debug`
  String get talker_type_debug => Intl.message(
        'Verbose & debug',
        name: 'talker_type_debug',
        desc: '',
        args: [],
      );

  /// `Verbose and debug logs count: {text}`
  String talker_type_debug_count(Object text) => Intl.message(
        'Verbose and debug logs count: $text',
        name: 'talker_type_debug_count',
        desc: '',
        args: [text],
      );

  /// `Good`
  String get talker_type_good => Intl.message(
        'Good',
        name: 'talker_type_good',
        desc: '',
        args: [],
      );

  /// `Good logs count: {text}`
  String talker_type_good_count(Object text) => Intl.message(
        'Good logs count: $text',
        name: 'talker_type_good_count',
        desc: '',
        args: [text],
      );

  /// `Providers`
  String get talker_type_provider => Intl.message(
        'Providers',
        name: 'talker_type_provider',
        desc: '',
        args: [],
      );

  /// `Provider logs count: {text}`
  String talker_type_provider_count(Object text) => Intl.message(
        'Provider logs count: $text',
        name: 'talker_type_provider_count',
        desc: '',
        args: [text],
      );

  /// `Info`
  String get talker_type_info => Intl.message(
        'Info',
        name: 'talker_type_info',
        desc: '',
        args: [],
      );

  /// `Info logs count: {text}`
  String talker_type_info_count(Object text) => Intl.message(
        'Info logs count: $text',
        name: 'talker_type_info_count',
        desc: '',
        args: [text],
      );

  /// `Warnings`
  String get talker_type_warnings => Intl.message(
        'Warnings',
        name: 'talker_type_warnings',
        desc: '',
        args: [],
      );

  /// `Warning logs count: {text}`
  String talker_type_warnings_count(Object text) => Intl.message(
        'Warning logs count: $text',
        name: 'talker_type_warnings_count',
        desc: '',
        args: [text],
      );

  /// `Exceptions`
  String get talker_type_exceptions => Intl.message(
        'Exceptions',
        name: 'talker_type_exceptions',
        desc: '',
        args: [],
      );

  /// `Exception logs count: {text}`
  String talker_type_exceptions_count(Object text) => Intl.message(
        'Exception logs count: $text',
        name: 'talker_type_exceptions_count',
        desc: '',
        args: [text],
      );

  /// `Errors`
  String get talker_type_errors => Intl.message(
        'Errors',
        name: 'talker_type_errors',
        desc: '',
        args: [],
      );

  /// `Error logs count: {text}`
  String talker_type_errors_count(Object text) => Intl.message(
        'Error logs count: $text',
        name: 'talker_type_errors_count',
        desc: '',
        args: [text],
      );

  /// `HTTP requests`
  String get talker_type_http => Intl.message(
        'HTTP requests',
        name: 'talker_type_http',
        desc: '',
        args: [],
      );

  /// `HTTP request logs count: {text}`
  String talker_http_requests_count(Object text) => Intl.message(
        'HTTP request logs count: $text',
        name: 'talker_http_requests_count',
        desc: '',
        args: [text],
      );

  /// `HTTP response logs count: {text}`
  String talker_http_responses_count(Object text) => Intl.message(
        'HTTP response logs count: $text',
        name: 'talker_http_responses_count',
        desc: '',
        args: [text],
      );

  /// `HTTP failure logs count: {text}`
  String talker_http_failues_count(Object text) => Intl.message(
        'HTTP failure logs count: $text',
        name: 'talker_http_failues_count',
        desc: '',
        args: [text],
      );

  /// `BLoC`
  String get talker_type_bloc => Intl.message(
        'BLoC',
        name: 'talker_type_bloc',
        desc: '',
        args: [],
      );

  /// `BLoC transitions count: {text}`
  String talker_bloc_transition_count(Object text) => Intl.message(
        'BLoC transitions count: $text',
        name: 'talker_bloc_transition_count',
        desc: '',
        args: [text],
      );

  /// `BLoC events count: {text}`
  String talker_bloc_events_count(Object text) => Intl.message(
        'BLoC events count: $text',
        name: 'talker_bloc_events_count',
        desc: '',
        args: [text],
      );

  /// `BLoC closes count: {text}`
  String talker_bloc_close_count(Object text) => Intl.message(
        'BLoC closes count: $text',
        name: 'talker_bloc_close_count',
        desc: '',
        args: [text],
      );

  /// `BLoC creates count: {text}`
  String talker_bloc_create_count(Object text) => Intl.message(
        'BLoC creates count: $text',
        name: 'talker_bloc_create_count',
        desc: '',
        args: [text],
      );

  /// `Actions`
  String get actions => Intl.message(
        'Actions',
        name: 'actions',
        desc: '',
        args: [],
      );

  /// `Reverse logs`
  String get reverse_logs => Intl.message(
        'Reverse logs',
        name: 'reverse_logs',
        desc: '',
        args: [],
      );

  /// `Copy all logs`
  String get copy_all_logs => Intl.message(
        'Copy all logs',
        name: 'copy_all_logs',
        desc: '',
        args: [],
      );

  /// `Collapse logs`
  String get collapse_logs => Intl.message(
        'Collapse logs',
        name: 'collapse_logs',
        desc: '',
        args: [],
      );

  /// `Expand logs`
  String get expand_logs => Intl.message(
        'Expand logs',
        name: 'expand_logs',
        desc: '',
        args: [],
      );

  /// `Clean history`
  String get clean_history => Intl.message(
        'Clean history',
        name: 'clean_history',
        desc: '',
        args: [],
      );

  /// `Share logs file`
  String get share_logs_file => Intl.message(
        'Share logs file',
        name: 'share_logs_file',
        desc: '',
        args: [],
      );

  /// `Log item is copied in clipboard`
  String get log_item_copied => Intl.message(
        'Log item is copied in clipboard',
        name: 'log_item_copied',
        desc: '',
        args: [],
      );

  /// `Basic settings`
  String get basic_settings => Intl.message(
        'Basic settings',
        name: 'basic_settings',
        desc: '',
        args: [],
      );

  /// `Enabled`
  String get enabled => Intl.message(
        'Enabled',
        name: 'enabled',
        desc: '',
        args: [],
      );

  /// `Use console logs`
  String get use_console_logs => Intl.message(
        'Use console logs',
        name: 'use_console_logs',
        desc: '',
        args: [],
      );

  /// `Use history`
  String get use_history => Intl.message(
        'Use history',
        name: 'use_history',
        desc: '',
        args: [],
      );

  /// `Settings`
  String get settings => Intl.message(
        'Settings',
        name: 'settings',
        desc: '',
        args: [],
      );

  /// `Search`
  String get search => Intl.message(
        'Search',
        name: 'search',
        desc: '',
        args: [],
      );

  /// `All logs copied in buffer`
  String get all_logs_copied => Intl.message(
        'All logs copied in buffer',
        name: 'all_logs_copied',
        desc: '',
        args: [],
      );

  /// `Oops, the page on this path`
  String get page_not_found => Intl.message(
        'Oops, the page on this path',
        name: 'page_not_found',
        desc: '',
        args: [],
      );

  /// `not found`
  String get not_found => Intl.message(
        'not found',
        name: 'not_found',
        desc: '',
        args: [],
      );

  /// `Go back to the main page`
  String get back_to_home => Intl.message(
        'Go back to the main page',
        name: 'back_to_home',
        desc: '',
        args: [],
      );

  /// `Report`
  String get fix => Intl.message(
        'Report',
        name: 'fix',
        desc: '',
        args: [],
      );

  /// `Clear cache`
  String get clear_cache => Intl.message(
        'Clear cache',
        name: 'clear_cache',
        desc: '',
        args: [],
      );

  /// `Cache cleared`
  String get cache_cleared => Intl.message(
        'Cache cleared',
        name: 'cache_cleared',
        desc: '',
        args: [],
      );

  /// `Error on clearing cache`
  String get error_cache_clearing => Intl.message(
        'Error on clearing cache',
        name: 'error_cache_clearing',
        desc: '',
        args: [],
      );

  /// `App version`
  String get app_version => Intl.message(
        'App version',
        name: 'app_version',
        desc: '',
        args: [],
      );

  /// `Build version`
  String get build_version => Intl.message(
        'Build version',
        name: 'build_version',
        desc: '',
        args: [],
      );

  /// `Change current environment`
  String get change_environment => Intl.message(
        'Change current environment',
        name: 'change_environment',
        desc: '',
        args: [],
      );

  /// `Go to logger`
  String get go_to_logger => Intl.message(
        'Go to logger',
        name: 'go_to_logger',
        desc: '',
        args: [],
      );

  /// `To open the dialog, it remains: {number}`
  String environment_tap_number(Object number) => Intl.message(
        'To open the dialog, it remains: $number',
        name: 'environment_tap_number',
        desc: '',
        args: [number],
      );

  /// `You have pushed the button this many times: {number}`
  String counter_times_text(Object number) => Intl.message(
        'You have pushed the button this many times: $number',
        name: 'counter_times_text',
        desc: '',
        args: [number],
      );

  /// `Performance tracking`
  String get performance_tracker => Intl.message(
        'Performance tracking',
        name: 'performance_tracker',
        desc: '',
        args: [],
      );

  /// `Login`
  String get login => Intl.message(
        'Login',
        name: 'login',
        desc: '',
        args: [],
      );

  /// `Initialization failed`
  String get initialization_failed => Intl.message(
        'Initialization failed',
        name: 'initialization_failed',
        desc: '',
        args: [],
      );

  /// `Error type`
  String get error_type => Intl.message(
        'Error type',
        name: 'error_type',
        desc: '',
        args: [],
      );

  /// `Retry`
  String get retry => Intl.message(
        'Retry',
        name: 'retry',
        desc: '',
        args: [],
      );

  /// `Log Out`
  String get logout => Intl.message(
        'Log Out',
        name: 'logout',
        desc: '',
        args: [],
      );

  /// `You are already in the logger page`
  String get you_already_in_logger => Intl.message(
        'You are already in the logger page',
        name: 'you_already_in_logger',
        desc: '',
        args: [],
      );

  /// `Turn on inspector`
  String get turn_on_inspector => Intl.message(
        'Turn on inspector',
        name: 'turn_on_inspector',
        desc: '',
        args: [],
      );

  /// `Turn off inspector`
  String get turn_off_inspector => Intl.message(
        'Turn off inspector',
        name: 'turn_off_inspector',
        desc: '',
        args: [],
      );

  /// `Viewing and managing application data`
  String get view_and_manage_data => Intl.message(
        'Viewing and managing application data',
        name: 'view_and_manage_data',
        desc: '',
        args: [],
      );

  /// `App data`
  String get app_data => Intl.message(
        'App data',
        name: 'app_data',
        desc: '',
        args: [],
      );

  /// `Total files count: {number}`
  String total_files_count(Object number) => Intl.message(
        'Total files count: $number',
        name: 'total_files_count',
        desc: '',
        args: [number],
      );

  /// `Check device info & package info`
  String get app_info => Intl.message(
        'Check device info & package info',
        name: 'app_info',
        desc: '',
        args: [],
      );

  /// `Copied to clipboard`
  String get copied_to_clipboard => Intl.message(
        'Copied to clipboard',
        name: 'copied_to_clipboard',
        desc: '',
        args: [],
      );

  /// `Copy`
  String get copy => Intl.message(
        'Copy',
        name: 'copy',
        desc: '',
        args: [],
      );

  /// `Cache size: {size}`
  String cache_size(Object size) => Intl.message(
        'Cache size: $size',
        name: 'cache_size',
        desc: '',
        args: [size],
      );
}

class AppLocalizationDelegate
    extends LocalizationsDelegate<ISpectGeneratedLocalization> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales => const <Locale>[
        Locale.fromSubtags(languageCode: 'en'),
        Locale.fromSubtags(languageCode: 'ru'),
      ];

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<ISpectGeneratedLocalization> load(Locale locale) =>
      ISpectGeneratedLocalization.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
