import 'package:ispectify/ispectify.dart';

/// Converts [LogDetails] into a formatted string for console output.
abstract interface class ILoggerFormatter {
  String format(
    LogDetails details,
    ConsoleSettings settings,
  );
}

/// Applies ANSI color per line and substitutes a placeholder for empty
/// payloads. Layout (level column, indent, metadata) is owned by
/// [ILogEntryFormatter]; this formatter intentionally does not reshape the
/// incoming message so single-line and multi-line entries align identically.
///
/// Coloring is applied per line so each line carries its own reset sequence —
/// terminals and log viewers that strip styling on `\n` keep the color of
/// every line intact.
base class ExtendedLoggerFormatter implements ILoggerFormatter {
  const ExtendedLoggerFormatter();

  @override
  String format(
    LogDetails details,
    ConsoleSettings settings,
  ) {
    final message = details.message?.toString();
    final text = (message == null || message.isEmpty)
        ? '(empty log message)'
        : message;

    if (!settings.enableColors) return text;

    return text.split('\n').map(details.pen.write).join('\n');
  }
}
