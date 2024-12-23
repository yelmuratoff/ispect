import 'package:ansicolor/ansicolor.dart';

/// Represents the severity levels for logging events.
///
/// The [LogLevel] enum defines various levels of log severity,
/// allowing developers to categorize log messages based on their importance.
enum LogLevel {
  /// Indicates a critical error that requires immediate attention.
  critical,

  /// Represents a general error in the application.
  error,

  /// Used for informational messages about application behavior.
  info,

  /// Represents messages used for debugging purposes.
  debug,

  /// Provides highly detailed log messages, often used during extensive debugging.
  verbose,

  /// Indicates a warning that may lead to potential issues.
  warning,

  /// Represents a successful operation or state in the application.
  success;

  AnsiPen get pen {
    return switch (this) {
      LogLevel.critical => AnsiPen()..xterm(196),
      LogLevel.error => AnsiPen()..red(),
      LogLevel.info => AnsiPen()..blue(),
      LogLevel.debug => AnsiPen()..xterm(245),
      LogLevel.verbose => AnsiPen()..xterm(245),
      LogLevel.warning => AnsiPen()..xterm(208),
      LogLevel.success => AnsiPen()..green(),
    };
  }
}
