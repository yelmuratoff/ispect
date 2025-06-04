import 'dart:js_interop';
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
void outputLog(String message) => message.split('\n').forEach(
      (line) => console.log(line.toJS),
    );
