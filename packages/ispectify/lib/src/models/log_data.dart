import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/enums/log_level.dart';

/// Represents the metadata for a log message.
///
/// The [LogData] class provides a structure to define essential properties
/// for a log entry, such as a unique identifier, title, color style, and log level.
class LogData {
  /// A unique identifier for the log message.
  ///
  /// The [key] allows easy categorization or filtering of log messages.
  final String key;

  /// The descriptive title of the log message.
  ///
  /// The [title] provides a human-readable label for the log,
  /// often describing the purpose or context of the log entry.
  final String title;

  /// The [AnsiPen] used to style the log message with colors.
  ///
  /// This property defines the appearance of the log output in the console,
  /// including foreground and background colors.
  final AnsiPen pen;

  /// The severity level of the log message.
  ///
  /// The [level] is represented by the [LogLevel] enum, indicating
  /// the importance or severity of the log entry.
  final LogLevel level;

  /// Creates a new instance of [LogData].
  ///
  /// ### Parameters:
  /// - [key]: A unique string identifier for the log.
  /// - [title]: A descriptive name for the log entry.
  /// - [pen]: An instance of [AnsiPen] to define the log's color style.
  /// - [level]: A [LogLevel] value representing the severity of the log.
  ///
  /// ### Example:
  /// ```dart
  /// final log = LogData(
  ///   key: 'analytics',
  ///   title: 'Amplitude',
  ///   pen: AnsiPen()..yellow(),
  ///   level: LogLevel.info,
  /// );
  /// ```
  const LogData({
    required this.key,
    required this.title,
    required this.pen,
    required this.level,
  });
}
