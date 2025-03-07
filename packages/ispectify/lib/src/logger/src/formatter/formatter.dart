import 'package:ispectify/ispectify.dart';

/// An interface for formatting log messages.
///
/// Implementations of this interface should define how logs are structured
/// when converted into a string representation.
abstract interface class LoggerFormatter {
  /// Formats the log details based on the provided settings.
  ///
  /// This method is responsible for transforming [LogDetails] into a human-readable
  /// string that follows specific formatting rules, such as adding visual elements
  /// (borders, symbols) and applying colorization (if enabled).
  ///
  /// - [details]: Contains the log message and additional metadata (e.g., log level).
  /// - [settings]: Defines formatting rules such as max line width, symbols, and color settings.
  ///
  /// Returns:
  /// A formatted log message as a string.
  String format(
    LogDetails details,
    LoggerSettings settings,
  );
}

/// A log formatter that enhances log readability by adding visual structure.
///
/// The [ExtendedLoggerFormatter] wraps log messages with top and bottom borders,
/// ensuring clear separation in console outputs. It also supports colorization
/// when enabled in [LoggerSettings].
///
/// Example output:
/// ```
/// ┌───────────────────────────────
/// │ Log message goes here...
/// └───────────────────────────────
/// ```
///
/// If colorization is enabled, ANSI escape codes will be applied to the output.
class ExtendedLoggerFormatter implements LoggerFormatter {
  /// Creates an instance of [ExtendedLoggerFormatter].
  ///
  /// This formatter does not hold any internal state and can be reused across logs.
  const ExtendedLoggerFormatter();

  @override
  String format(
    LogDetails details,
    LoggerSettings settings,
  ) {
    // Generate top and bottom borders using ConsoleUtils.
    final topLine = ConsoleUtils.topLine(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );
    final bottomLine = ConsoleUtils.bottomLine(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );

    // Extract the log message, ensuring it is a valid string.
    final message = details.message?.toString() ?? '';

    // Prepare bordered log lines. If the message is empty, show a placeholder.
    final msgBorderedLines = message.isEmpty
        ? ['│ (empty log message)'] // Placeholder for empty messages.
        : message.split('\n').map((line) => '│ $line');

    // Construct the final log output with borders.
    final formattedLines = [
      topLine,
      ...msgBorderedLines,
      bottomLine,
    ];

    // Apply colorization if enabled, otherwise return the plain log.
    return settings.enableColors
        ? formattedLines.map(details.pen.write).join('\n')
        : formattedLines.join('\n');
  }
}
