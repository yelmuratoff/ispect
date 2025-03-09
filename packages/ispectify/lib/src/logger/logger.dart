import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/filter/logger_filter.dart';
import 'package:ispectify/src/formatter/formatter.dart';
import 'package:ispectify/src/logger/logger_io.dart'
    if (dart.library.html) 'logger_html.dart'
    if (dart.library.js_interop) 'logger_web.dart';
import 'package:ispectify/src/models/log_details.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/settings.dart';

/// A logger class for handling structured and formatted logging.
///
/// [ISpectifyLogger] provides multiple logging levels and supports
/// custom filtering, formatting, and output handling.
class ISpectifyLogger {
  /// Creates an instance of [ISpectifyLogger] with optional configurations.
  ///
  /// - [settings]: Logger configuration settings. Defaults to [LoggerSettings()].
  /// - [formatter]: Defines how logs should be formatted. Defaults to [ExtendedLoggerFormatter()].
  /// - [filter]: A filter to determine whether logs should be recorded.
  /// - [output]: A callback function to handle log output (e.g., print to console).
  ISpectifyLogger({
    LoggerSettings? settings,
    this.formatter = const ExtendedLoggerFormatter(),
    ILoggerFilter? filter,
    void Function(String message)? output,
  }) {
    this.settings = settings ?? LoggerSettings();
    _output = output ?? outputLog;
    _filter = filter;
    ansiColorDisabled = false;
  }

  /// Logger settings that define behavior, such as enabled state and color mappings.
  late final LoggerSettings settings;

  /// Formatter responsible for structuring log messages.
  final LoggerFormatter formatter;

  /// Output function for writing logs (e.g., console output).
  late final void Function(String message) _output;

  /// Optional filter that determines whether a log message should be recorded.
  ILoggerFilter? _filter;

  /// Logs a message with an optional [level] and [pen] (color).
  ///
  /// - [msg]: The message to log.
  /// - [level]: The severity level of the log. Defaults to [LogLevel.debug].
  /// - [pen]: ANSI color pen for styling logs. If not provided, defaults to settings-based colors.
  void log(Object? msg, {LogLevel? level, AnsiPen? pen}) {
    if (!settings.enable) return;

    final selectedLevel = level ?? LogLevel.debug;
    final selectedPen =
        pen ?? settings.colors[selectedLevel] ?? (AnsiPen()..gray());

    if (_filter?.shouldLog(msg, selectedLevel) ?? true) {
      final formattedMsg = formatter.format(
        LogDetails(message: msg, level: selectedLevel, pen: selectedPen),
        settings,
      );
      _output(formattedMsg);
    }
  }

  /// Logs a critical-level message.
  void critical(Object? msg) => log(msg, level: LogLevel.critical);

  /// Logs an error-level message.
  void error(Object? msg) => log(msg, level: LogLevel.error);

  /// Logs a warning-level message.
  void warning(Object? msg) => log(msg, level: LogLevel.warning);

  /// Logs a debug-level message.
  void debug(Object? msg) => log(msg);

  /// Logs a verbose-level message.
  void verbose(Object? msg) => log(msg, level: LogLevel.verbose);

  /// Logs an info-level message.
  void info(Object? msg) => log(msg, level: LogLevel.info);

  /// Returns a new instance of [ISpectifyLogger] with modified properties.
  ///
  /// If a parameter is `null`, the existing instance values are preserved.
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
}
