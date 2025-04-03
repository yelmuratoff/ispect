import 'dart:js_interop';

import 'package:web/web.dart';

/// Outputs a log message to the browser's console.
///
/// Splits the provided [message] by newline characters and logs each line
/// individually to the console using the `console.log` method.
///
/// - [message]: The log message to be output. Each line of the message
///   will be converted to a JavaScript string using the `toJS` method
///   before being logged.
void outputLog(String message) => message.split('\n').forEach(
      (element) => console.log(message.toJS),
    );
