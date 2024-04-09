// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(size) => "Cache size: ${size}";

  static String m1(number) =>
      "You have pushed the button this many times: ${number}";

  static String m2(number) => "To open the dialog, it remains: ${number}";

  static String m3(text) => "BLoC closes count: ${text}";

  static String m4(text) => "BLoC creates count: ${text}";

  static String m5(text) => "BLoC events count: ${text}";

  static String m6(text) => "BLoC transitions count: ${text}";

  static String m7(text) => "HTTP failure logs count: ${text}";

  static String m8(text) => "HTTP request logs count: ${text}";

  static String m9(text) => "HTTP response logs count: ${text}";

  static String m10(text) => "Verbose and debug logs count: ${text}";

  static String m11(text) => "Error logs count: ${text}";

  static String m12(text) => "Exception logs count: ${text}";

  static String m13(text) => "Good logs count: ${text}";

  static String m14(text) => "Info logs count: ${text}";

  static String m15(text) => "Provider logs count: ${text}";

  static String m16(text) => "Warning logs count: ${text}";

  static String m17(number) => "Total files count: ${number}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "actions": MessageLookupByLibrary.simpleMessage("Actions"),
        "all_logs_copied":
            MessageLookupByLibrary.simpleMessage("All logs copied in buffer"),
        "app_data": MessageLookupByLibrary.simpleMessage("App data"),
        "app_info": MessageLookupByLibrary.simpleMessage(
            "Check device info & package info"),
        "app_version": MessageLookupByLibrary.simpleMessage("App version"),
        "back_to_home":
            MessageLookupByLibrary.simpleMessage("Go back to the main page"),
        "basic_settings":
            MessageLookupByLibrary.simpleMessage("Basic settings"),
        "build_version": MessageLookupByLibrary.simpleMessage("Build version"),
        "cache_cleared": MessageLookupByLibrary.simpleMessage("Cache cleared"),
        "cache_size": m0,
        "change_environment":
            MessageLookupByLibrary.simpleMessage("Change current environment"),
        "change_theme": MessageLookupByLibrary.simpleMessage("Change theme"),
        "clean_history": MessageLookupByLibrary.simpleMessage("Clean history"),
        "clear_cache": MessageLookupByLibrary.simpleMessage("Clear cache"),
        "collapse_logs": MessageLookupByLibrary.simpleMessage("Collapse logs"),
        "copied_to_clipboard":
            MessageLookupByLibrary.simpleMessage("Copied to clipboard"),
        "copy": MessageLookupByLibrary.simpleMessage("Copy"),
        "copy_all_logs": MessageLookupByLibrary.simpleMessage("Copy all logs"),
        "counter_times_text": m1,
        "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
        "environment_tap_number": m2,
        "error_cache_clearing":
            MessageLookupByLibrary.simpleMessage("Error on clearing cache"),
        "error_type": MessageLookupByLibrary.simpleMessage("Error type"),
        "expand_logs": MessageLookupByLibrary.simpleMessage("Expand logs"),
        "fix": MessageLookupByLibrary.simpleMessage("Report"),
        "go_to_logger": MessageLookupByLibrary.simpleMessage("Go to logger"),
        "initialization_failed":
            MessageLookupByLibrary.simpleMessage("Initialization failed"),
        "log_item_copied": MessageLookupByLibrary.simpleMessage(
            "Log item is copied in clipboard"),
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "logout": MessageLookupByLibrary.simpleMessage("Log Out"),
        "not_found": MessageLookupByLibrary.simpleMessage("not found"),
        "page_not_found":
            MessageLookupByLibrary.simpleMessage("Oops, the page on this path"),
        "performance_tracker":
            MessageLookupByLibrary.simpleMessage("Performance tracking"),
        "retry": MessageLookupByLibrary.simpleMessage("Retry"),
        "reverse_logs": MessageLookupByLibrary.simpleMessage("Reverse logs"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "share_logs_file":
            MessageLookupByLibrary.simpleMessage("Share logs file"),
        "talker_bloc_close_count": m3,
        "talker_bloc_create_count": m4,
        "talker_bloc_events_count": m5,
        "talker_bloc_transition_count": m6,
        "talker_http_failues_count": m7,
        "talker_http_requests_count": m8,
        "talker_http_responses_count": m9,
        "talker_type_bloc": MessageLookupByLibrary.simpleMessage("BLoC"),
        "talker_type_debug":
            MessageLookupByLibrary.simpleMessage("Verbose & debug"),
        "talker_type_debug_count": m10,
        "talker_type_errors": MessageLookupByLibrary.simpleMessage("Errors"),
        "talker_type_errors_count": m11,
        "talker_type_exceptions":
            MessageLookupByLibrary.simpleMessage("Exceptions"),
        "talker_type_exceptions_count": m12,
        "talker_type_good": MessageLookupByLibrary.simpleMessage("Good"),
        "talker_type_good_count": m13,
        "talker_type_http":
            MessageLookupByLibrary.simpleMessage("HTTP requests"),
        "talker_type_info": MessageLookupByLibrary.simpleMessage("Info"),
        "talker_type_info_count": m14,
        "talker_type_provider":
            MessageLookupByLibrary.simpleMessage("Providers"),
        "talker_type_provider_count": m15,
        "talker_type_warnings":
            MessageLookupByLibrary.simpleMessage("Warnings"),
        "talker_type_warnings_count": m16,
        "total_files_count": m17,
        "turn_off_inspector":
            MessageLookupByLibrary.simpleMessage("Turn off inspector"),
        "turn_on_inspector":
            MessageLookupByLibrary.simpleMessage("Turn on inspector"),
        "use_console_logs":
            MessageLookupByLibrary.simpleMessage("Use console logs"),
        "use_history": MessageLookupByLibrary.simpleMessage("Use history"),
        "view_and_manage_data": MessageLookupByLibrary.simpleMessage(
            "Viewing and managing application data"),
        "you_already_in_logger": MessageLookupByLibrary.simpleMessage(
            "You are already in the logger page")
      };
}
