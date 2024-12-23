import 'dart:js_util';
import 'package:ispectify/src/reporter/reporter.dart';

/// A log reporter for web environments.
///
/// The [WebLogReporter] class implements the [ILogReporter] interface
/// and sends log messages to the browser's developer console.
final class WebLogReporter implements ILogReporter {
  /// Creates an instance of [WebLogReporter].
  const WebLogReporter();

  /// Reports a log message to the browser's developer console.
  ///
  /// This method utilizes JavaScript interop to call the `console.log`
  /// method in a web environment, allowing messages to be displayed
  /// in the browser's developer tools.
  ///
  /// ### Parameters:
  /// - [message]: The log message to be reported.
  ///
  /// ### Example:
  /// ```dart
  /// final reporter = WebLogReporter();
  /// reporter.report(message: 'This is a log message.');
  /// ```
  @override
  void report({
    required String message,
  }) {
    // Access the global `console` object in the browser environment.
    final console = getProperty(globalThis, 'console');

    // Call the `log` method on the `console` object with the given message.
    callMethod(
      console,
      'log',
      [message],
    );
  }
}
