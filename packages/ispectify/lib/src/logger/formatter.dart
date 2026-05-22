import 'package:ispectify/ispectify.dart';

/// Converts [LogDetails] into a formatted string for console output.
abstract interface class ILoggerFormatter {
  String format(
    LogDetails details,
    ConsoleSettings settings,
  );
}

/// Renders single-line logs verbatim and indents continuation lines of
/// multi-line payloads (e.g. network curl dumps, JSON bodies).
///
/// ```
/// Single-line message
///
/// - First line of multi-line payload
///   Second line
///   Third line
/// ```
base class ExtendedLoggerFormatter implements ILoggerFormatter {
  const ExtendedLoggerFormatter();

  @override
  String format(
    LogDetails details,
    ConsoleSettings settings,
  ) {
    final message = details.message?.toString() ?? '';

    final List<String> lines;
    if (message.isEmpty) {
      lines = ['(empty log message)'];
    } else {
      final rawLines = message.split('\n');
      if (rawLines.length == 1) {
        lines = rawLines;
      } else {
        lines = [
          '- ${rawLines.first}',
          ...rawLines.skip(1).map((line) => '  $line'),
        ];
      }
    }

    return settings.enableColors
        ? lines.map(details.pen.write).join('\n')
        : lines.join('\n');
  }
}
