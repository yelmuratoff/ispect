import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/config/config.dart';
import 'package:ispectify/src/models/log_data.dart';
import 'package:ispectify/src/utils/console_utils.dart';
import 'package:ispectify/src/utils/date_utils.dart';

/// Defines the interface for log formatters.
///
/// Implementations of [ILogFormatter] should provide a way to format log
/// messages with optional metadata ([LogData]).
abstract interface class ILogFormatter {
  /// Default constructor for [ILogFormatter].
  const ILogFormatter();

  /// Formats a log message with optional metadata.
  ///
  /// ### Parameters:
  /// - [message]: The log message to format.
  /// - [data]: Optional metadata about the log, such as styling and log level.
  /// - [config]: The configuration for formatting logs, such as line symbols
  ///   and color settings. Defaults to a basic [LoggerConfig].
  ///
  /// ### Returns:
  /// A formatted string representing the log message.
  String format({
    required String message,
    required LogData? data,
    required ILoggerConfig config,
  });
}

/// A default implementation of the [ILogFormatter] interface.
///
/// The [LogFormatter] class formats log messages with optional metadata
/// and supports configurable styles, such as borders, colors, and log length.
final class LogFormatter implements ILogFormatter {
  /// Creates a new instance of [LogFormatter].
  const LogFormatter();

  /// Formats a log message with borders, optional colors, and metadata.
  ///
  /// ### Parameters:
  /// - [message]: The log message to format.
  /// - [data]: Optional [LogData] providing additional metadata, such as a
  ///   specific [AnsiPen] for styling.
  /// - [config]: The configuration for formatting logs, such as line symbols
  ///   and color settings. Defaults to a basic [LoggerConfig].
  ///
  /// ### Returns:
  /// A formatted string with optional colors and borders based on the configuration.
  ///
  /// ### Example:
  /// ```dart
  /// final formatter = LogFormatter();
  /// final logData = LogData(
  ///   key: 'INFO',
  ///   title: 'Sample Log',
  ///   pen: AnsiPen()..blue(),
  ///   level: LogLevel.info,
  /// );
  ///
  /// final log = formatter.format(
  ///   message: 'This is a log message.',
  ///   data: logData,
  /// );
  /// print(log);
  /// ```
  @override
  String format({
    required String message,
    required LogData? data,
    required ILoggerConfig config,
  }) {
    final buffer = StringBuffer();

    if (config.showTimestamp) {
      buffer.write(DateUtils.format(DateTime.now()));
      buffer.write(' | ');
    }

    if (config.showKey && data != null) {
      buffer.write('${data.key} | ');
    }

    if (config.showName && data != null) {
      buffer.write(data.title);
    }

    buffer.write('\n$message');

    // Generate the top and bottom borders.
    final underline = ConsoleUtils.bottomLine(
      config.symbolLength,
      lineSymbol: config.lineSymbol,
      withCorner: true,
    );

    final topline = ConsoleUtils.topLine(
      config.symbolLength,
      lineSymbol: config.lineSymbol,
      withCorner: true,
    );

    // Format each line of the message with a border.
    final msgBorderedLines = buffer.toString().split('\n').map((e) => '│ $e');

    // If colors are disabled, return the plain formatted message.
    if (!config.isColorsEnabled) {
      return '$topline\n${msgBorderedLines.join('\n')}\n$underline';
    }

    // Apply colors if enabled.
    var lines = [topline, ...msgBorderedLines, underline];
    lines = lines
        .map(
          (e) => (data?.pen ?? (AnsiPen()..blue())).write(e),
        )
        .toList();
    final coloredMsg = lines.join('\n');
    return coloredMsg;
  }
}
