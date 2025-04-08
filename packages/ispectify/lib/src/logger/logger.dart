import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/filter/logger_filter.dart';
import 'package:ispectify/src/formatter/formatter.dart';
import 'package:ispectify/src/logger/logger_io.dart'
    if (dart.library.html) 'logger_html.dart'
    if (dart.library.js_interop) 'logger_web.dart';
import 'package:ispectify/src/models/log_details.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/settings.dart';

/// A logger class for structured and formatted logging.
///
/// Supports multiple log levels, colorized output, filtering,
/// and customizable formatting/output handling.
class ISpectifyLogger {
  /// Creates an instance of `ISpectifyLogger` with optional configurations.
  ///
  /// - `settings`: Logger configuration settings. Defaults to `LoggerSettings()`.
  /// - `formatter`: Formatter for log messages. Defaults to `ExtendedLoggerFormatter()`.
  /// - `filter`: Optional log filter.
  /// - `output`: Optional output function (e.g., `print`).
  ISpectifyLogger({
    LoggerSettings? settings,
    this.formatter = const ExtendedLoggerFormatter(),
    ILoggerFilter? filter,
    void Function(String message)? output,
  })  : settings = settings ?? LoggerSettings(),
        _filter = filter,
        _output = output ?? outputLog {
    ansiColorDisabled = false;
  }

  /// Logger settings such as enabled state and color mapping.
  final LoggerSettings settings;

  /// Formatter for structuring log messages.
  final LoggerFormatter formatter;

  /// Output function to handle final log message.
  final void Function(String message) _output;

  /// Optional filter to determine whether a log should be logged.
  final ILoggerFilter? _filter;

  /// Logs a message at a specified level with optional ANSI color pen.
  void log(Object? msg, {LogLevel? level, AnsiPen? pen}) {
    if (!settings.enable ||
        !(_filter?.shouldLog(msg, level ?? LogLevel.debug) ?? true)) {
      return;
    }

    final selectedLevel = level ?? LogLevel.debug;
    final selectedPen =
        pen ?? settings.colors[selectedLevel] ?? (AnsiPen()..gray());

    final formattedMsg = formatter.format(
      LogDetails(message: msg, level: selectedLevel, pen: selectedPen),
      settings,
    );
    _output(formattedMsg);
  }

  /// Logs a critical-level message.
  void critical(Object? msg) => log(msg, level: LogLevel.critical);

  /// Logs an error-level message.
  void error(Object? msg) => log(msg, level: LogLevel.error);

  /// Logs a warning-level message.
  void warning(Object? msg) => log(msg, level: LogLevel.warning);

  /// Logs a debug-level message.
  void debug(Object? msg) => log(msg, level: LogLevel.debug);

  /// Logs a verbose-level message.
  void verbose(Object? msg) => log(msg, level: LogLevel.verbose);

  /// Logs an info-level message.
  void info(Object? msg) => log(msg, level: LogLevel.info);

  /// Creates a new `ISpectifyLogger` instance with overridden properties.
  ISpectifyLogger copyWith({
    LoggerSettings? settings,
    LoggerFormatter? formatter,
    ILoggerFilter? filter,
    void Function(String message)? output,
  }) =>
      ISpectifyLogger(
        settings: settings ?? this.settings,
        formatter: formatter ?? this.formatter,
        filter: filter ?? _filter,
        output: output ?? _output,
      );

  @override
  String toString() =>
      'ISpectifyLogger(enabled: ${settings.enable}, level: ${settings.level})';
}
