import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/utils/console_utils.dart';

/// Configuration settings for ISpectify logger.
///
/// This class defines how logs are formatted, colored, and displayed.
class LoggerSettings {
  /// Creates an instance of `LoggerSettings` with customizable options.
  ///
  /// - `colors`: Custom ANSI colors for different log levels.
  /// - `enable`: Enables or disables logging (default: `true`).
  /// - `defaultTitle`: Default title for logs (default: `'Log'`).
  /// - `level`: Minimum log level to be recorded (default: `LogLevel.verbose`).
  /// - `lineSymbol`: The symbol used for log separators (default: `'─'`).
  /// - `maxLineWidth`: Maximum width for log lines (default: `110`).
  /// - `enableColors`: Enables ANSI colors in console output (default: `true`).
  LoggerSettings({
    Map<LogLevel, AnsiPen>? colors,
    this.enable = true,
    this.defaultTitle = 'Log',
    this.level = LogLevel.verbose,
    this.lineSymbol = '─',
    this.maxLineWidth = 110,
    this.enableColors = true,
  }) : colors = {...ConsoleUtils.ansiColors, if (colors != null) ...colors};

  /// ANSI colors for log levels.
  final Map<LogLevel, AnsiPen> colors;

  /// Whether logging is enabled.
  bool enable;

  /// Default log title.
  final String defaultTitle;

  /// Minimum log level required for a log to be recorded.
  final LogLevel level;

  /// Symbol used for log line separators.
  final String lineSymbol;

  /// Maximum width for log messages.
  final int maxLineWidth;

  /// Whether ANSI colors are enabled in logs.
  final bool enableColors;

  /// Creates a new instance of `LoggerSettings` with modified properties.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  LoggerSettings copyWith({
    Map<LogLevel, AnsiPen>? colors,
    bool? enable,
    String? defaultTitle,
    LogLevel? level,
    String? lineSymbol,
    int? maxLineWidth,
    bool? enableColors,
  }) =>
      LoggerSettings(
        colors: colors ?? this.colors,
        enable: enable ?? this.enable,
        defaultTitle: defaultTitle ?? this.defaultTitle,
        level: level ?? this.level,
        lineSymbol: lineSymbol ?? this.lineSymbol,
        maxLineWidth: maxLineWidth ?? this.maxLineWidth,
        enableColors: enableColors ?? this.enableColors,
      );
}
