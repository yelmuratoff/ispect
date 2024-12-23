import 'dart:developer' as developer;
import 'dart:io';

import 'package:ispectify/src/config/config.dart';
import 'package:ispectify/src/enums/log_level.dart';
import 'package:ispectify/src/formatter/formatter.dart';
import 'package:ispectify/src/models/log_data.dart';

/// A customizable logger for managing console and developer logs.
///
/// The [Logger] class provides a structured way to log messages with various
/// log levels, optional metadata, and support for formatted output.
class Logger {
  /// Creates a new instance of [Logger].
  ///
  /// ### Parameters:
  /// - [name]: An optional name for the logger instance.
  /// - [config]: The logger configuration, defining how logs are styled and displayed. Defaults to [LoggerConfig].
  /// - [formatter]: A formatter for customizing log message formatting. Defaults to [LogFormatter].
  Logger({
    this.name,
    this.config = const LoggerConfig(),
    this.formatter = const LogFormatter(),
  });

  /// The optional name of the logger, useful for categorizing logs.
  final String? name;

  /// The formatter used to format log messages.
  final ILogFormatter formatter;

  /// The configuration used for logging settings.
  final ILoggerConfig config;

  /// Logs a generic message with optional metadata.
  ///
  /// ### Parameters:
  /// - [message]: The log message to be displayed.
  /// - [data]: Optional metadata of type [LogData] for additional context or styling.
  void log(dynamic message, {LogData? data}) {
    // Format the message using the provided formatter and configuration.
    final formattedMessage = formatter.format(
      message: message,
      data: data,
      config: config,
    );

    // Print to the console or use the developer logger if ANSI is unsupported.
    if (_isAnsiSupported) {
      print(formattedMessage);
    } else {
      developer.log(
        formattedMessage,
        name: name ?? '',
      );
    }
  }

  /// Logs an informational message.
  void info(dynamic message) {
    log(
      message,
      data: LogData(
        key: 'info',
        title: 'Info',
        pen: LogLevel.info.pen,
        level: LogLevel.info,
      ),
    );
  }

  /// Logs a debug message.
  void debug(dynamic message) {
    log(
      message,
      data: LogData(
        key: 'debug',
        title: 'Debug',
        pen: LogLevel.debug.pen,
        level: LogLevel.debug,
      ),
    );
  }

  /// Logs a warning message.
  void warning(dynamic message) {
    log(
      message,
      data: LogData(
        key: 'warning',
        title: 'Warning',
        pen: LogLevel.warning.pen,
        level: LogLevel.warning,
      ),
    );
  }

  /// Logs an error message.
  void error(dynamic message) {
    log(
      message,
      data: LogData(
        key: 'error',
        title: 'Error',
        pen: LogLevel.error.pen,
        level: LogLevel.error,
      ),
    );
  }

  /// Logs a critical message.
  void critical(dynamic message) {
    log(
      message,
      data: LogData(
        key: 'critical',
        title: 'Critical',
        pen: LogLevel.critical.pen,
        level: LogLevel.critical,
      ),
    );
  }

  /// Logs a success message.
  void success(dynamic message) {
    log(
      message,
      data: LogData(
        key: 'success',
        title: 'Success',
        pen: LogLevel.success.pen,
        level: LogLevel.success,
      ),
    );
  }

  /// Checks if the current terminal supports ANSI escape sequences.
  bool get _isAnsiSupported => stdout.supportsAnsiEscapes;
}
