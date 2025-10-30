import 'package:ispectify/ispectify.dart';

/// An interface for formatting log messages.
///
/// Implementations of this interface should define how logs are structured
/// when converted into a string representation.
abstract interface class ILoggerFormatter {
  /// Formats the log details based on the provided settings.
  ///
  /// This method is responsible for transforming `LogDetails` into a human-readable
  /// string that follows specific formatting rules, such as adding visual elements
  /// (borders, symbols) and applying colorization (if enabled).
  ///
  /// - `details`: Contains the log message and additional metadata (e.g., log level).
  /// - `settings`: Defines formatting rules such as max line width, symbols, and color settings.
  ///
  /// Returns:
  /// A formatted log message as a string.
  String format(
    LogDetails details,
    LoggerSettings settings,
  );
}

/// A simple, readable log formatter.
///
/// The `ExtendedLoggerFormatter` prefixes the first line with a dash and indents
/// subsequent lines for clarity. If colors are enabled in `LoggerSettings`, ANSI
/// styles are applied to the entire message.
///
/// Example output:
/// - First line
///   Second line
///   Third line
class ExtendedLoggerFormatter implements ILoggerFormatter {
  /// Creates an instance of `ExtendedLoggerFormatter`.
  ///
  /// This formatter does not hold any internal state and can be reused across logs.
  const ExtendedLoggerFormatter();

  @override
  String format(
    LogDetails details,
    LoggerSettings settings,
  ) {
    // Extract the log message, ensuring it is a valid string.
    final message = details.message?.toString() ?? '';

    // Prepare bordered log lines. If the message is empty, show a placeholder.
    final List<String> msgBorderedLines;
    if (message.isEmpty) {
      msgBorderedLines = ['- (empty log message)'];
    } else {
      final lines = message.split('\n');
      msgBorderedLines = [
        '- ${lines.first}',
        ...lines.skip(1).map((line) => '  $line'),
      ];
    }

    // Construct the final log output.
    final formattedLines = [
      ...msgBorderedLines,
    ];

    // Apply colorization if enabled, otherwise return the plain log.
    return settings.enableColors
        ? formattedLines.map(details.pen.write).join('\n')
        : formattedLines.join('\n');
  }
}
