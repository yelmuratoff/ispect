import 'dart:js_interop';

import 'package:ispectify/src/models/log_level.dart';
import 'package:web/web.dart';

/// Outputs a log message to the browser's console.
///
/// Splits the provided `message` by newline characters (`\n`) and logs each
/// line individually to the browser's console using `console.log`.
///
/// This function is intended for use in web environments where `console`
/// is available.
///
/// Example:
/// ```dart
/// outputLog('Line 1\nLine 2');
/// // Logs "Line 1" and "Line 2" separately to the console.
/// ```
///
/// `message`: The log message to be output to the console.
void outputLog(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    message.split('\n').forEach(
          (line) => console.log(line.toJS),
        );
