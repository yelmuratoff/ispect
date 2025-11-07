import 'package:ispect/ispect.dart';

/// Extensions for conditional error handling based on settings.
///
/// These extensions eliminate duplication of error logging patterns throughout
/// the codebase, ensuring consistent error handling behavior.
extension ErrorHandlingExtensions on ISpectLogger {
  /// Conditionally handles an error based on settings.
  ///
  /// **Purpose:** Logs errors only when console logging is enabled in settings
  void handleConditionally({
    required Object exception,
    required StackTrace stackTrace,
    required ISpectLoggerOptions settings,
  }) {
    if (settings.useConsoleLogs) {
      handle(exception: exception, stackTrace: stackTrace);
    }
  }

  /// Conditionally logs a warning message based on settings.
  ///
  /// **Purpose:** Logs warnings only when console logging is enabled
  void warningConditionally({
    required String message,
    required ISpectLoggerOptions settings,
  }) {
    if (settings.useConsoleLogs) {
      warning(message);
    }
  }

  /// Conditionally logs an info message based on settings.
  ///
  /// **Purpose:** Logs informational messages only when console logging is enabled
  void infoConditionally({
    required String message,
    required ISpectLoggerOptions settings,
  }) {
    if (settings.useConsoleLogs) {
      info(message);
    }
  }

  /// Conditionally logs a debug message based on settings.
  ///
  /// **Purpose:** Logs debug messages only when console logging is enabled
  void debugConditionally({
    required String message,
    required ISpectLoggerOptions settings,
  }) {
    if (settings.useConsoleLogs) {
      debug(message);
    }
  }
}
