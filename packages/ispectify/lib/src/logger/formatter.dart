import 'package:ispectify/ispectify.dart';

/// Converts [LogDetails] into a formatted string for console output.
abstract interface class ILoggerFormatter {
  String format(
    LogDetails details,
    ConsoleSettings settings,
  );
}

/// Prefixes the first line with `- ` and indents subsequent lines.
///
/// ```
/// - First line
///   Second line
///   Third line
/// ```
class ExtendedLoggerFormatter implements ILoggerFormatter {
  const ExtendedLoggerFormatter();

  @override
  String format(
    LogDetails details,
    ConsoleSettings settings,
  ) {
    final message = details.message?.toString() ?? '';

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

    return settings.enableColors
        ? msgBorderedLines.map(details.pen.write).join('\n')
        : msgBorderedLines.join('\n');
  }
}
