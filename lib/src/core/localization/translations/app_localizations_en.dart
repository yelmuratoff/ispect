import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([super.locale = 'en']);

  @override
  String get change_theme => 'Change theme';

  @override
  String get talker_type_debug => 'Verbose & debug';

  @override
  String talker_type_debug_count(Object text) {
    return 'Verbose and debug logs count: $text';
  }

  @override
  String get talker_type_good => 'Good';

  @override
  String talker_type_good_count(Object text) {
    return 'Good logs count: $text';
  }

  @override
  String get talker_type_provider => 'Providers';

  @override
  String talker_type_provider_count(Object text) {
    return 'Provider logs count: $text';
  }

  @override
  String get talker_type_info => 'Info';

  @override
  String talker_type_info_count(Object text) {
    return 'Info logs count: $text';
  }

  @override
  String get talker_type_warnings => 'Warnings';

  @override
  String talker_type_warnings_count(Object text) {
    return 'Warning logs count: $text';
  }

  @override
  String get talker_type_exceptions => 'Exceptions';

  @override
  String talker_type_exceptions_count(Object text) {
    return 'Exception logs count: $text';
  }

  @override
  String get talker_type_errors => 'Errors';

  @override
  String talker_type_errors_count(Object text) {
    return 'Error logs count: $text';
  }

  @override
  String get talker_type_http => 'HTTP requests';

  @override
  String talker_http_requests_count(Object text) {
    return 'HTTP request logs count: $text';
  }

  @override
  String talker_http_responses_count(Object text) {
    return 'HTTP response logs count: $text';
  }

  @override
  String talker_http_failues_count(Object text) {
    return 'HTTP failure logs count: $text';
  }

  @override
  String get talker_type_bloc => 'BLoC';

  @override
  String talker_bloc_transition_count(Object text) {
    return 'BLoC transitions count: $text';
  }

  @override
  String talker_bloc_events_count(Object text) {
    return 'BLoC events count: $text';
  }

  @override
  String talker_bloc_close_count(Object text) {
    return 'BLoC closes count: $text';
  }

  @override
  String talker_bloc_create_count(Object text) {
    return 'BLoC creates count: $text';
  }

  @override
  String get actions => 'Actions';

  @override
  String get reverse_logs => 'Reverse logs';

  @override
  String get copy_all_logs => 'Copy all logs';

  @override
  String get collapse_logs => 'Collapse logs';

  @override
  String get expand_logs => 'Expand logs';

  @override
  String get clean_history => 'Clean history';

  @override
  String get share_logs_file => 'Share logs file';

  @override
  String get log_item_copied => 'Log item is copied in clipboard';

  @override
  String get basic_settings => 'Basic settings';

  @override
  String get enabled => 'Enabled';

  @override
  String get use_console_logs => 'Use console logs';

  @override
  String get use_history => 'Use history';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get all_logs_copied => 'All logs copied in buffer';

  @override
  String get page_not_found => 'Oops, the page on this path';

  @override
  String get not_found => 'not found';

  @override
  String get back_to_home => 'Go back to the main page';

  @override
  String get fix => 'Report';

  @override
  String get clear_cache => 'Clear cache';

  @override
  String get cache_cleared => 'Cache cleared';

  @override
  String get error_cache_clearing => 'Error on clearing cache';

  @override
  String get app_version => 'App version';

  @override
  String get build_version => 'Build version';

  @override
  String get change_environment => 'Change current environment';

  @override
  String get go_to_logger => 'Go to logger';

  @override
  String environment_tap_number(Object number) {
    return 'To open the dialog, it remains: $number';
  }

  @override
  String counter_times_text(Object number) {
    return 'You have pushed the button this many times: $number';
  }

  @override
  String get performance_tracker => 'Performance tracking';

  @override
  String get login => 'Login';

  @override
  String get initialization_failed => 'Initialization failed';

  @override
  String get error_type => 'Error type';

  @override
  String get retry => 'Retry';

  @override
  String get logout => 'Log Out';

  @override
  String get you_already_in_logger => 'You are already in the logger page';

  @override
  String get turn_on_inspector => 'Turn on inspector';

  @override
  String get turn_off_inspector => 'Turn off inspector';

  @override
  String get view_and_manage_data => 'Viewing and managing application data';

  @override
  String get app_data => 'App data';

  @override
  String total_files_count(Object number) {
    return 'Total files count: $number';
  }

  @override
  String get app_info => 'Check device info & package info';

  @override
  String get copied_to_clipboard => 'Copied to clipboard';

  @override
  String get copy => 'Copy';
}
