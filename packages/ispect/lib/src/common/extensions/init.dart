import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';

/// Extension on `ISpectify` for Flutter-specific configurations.
///
/// This extension provides an initializer method with a default Flutter output
/// handler that adapts logging behavior based on the target platform.
extension ISpectFlutter on ISpectLogger {
  /// Initializes an instance of `ISpectify` with Flutter-specific settings.
  ///
  /// This method sets up logging, observation, filtering, and options, ensuring
  /// that the logger uses a platform-adaptive output method.
  ///
  /// - `logger`: Custom logger instance (defaults to `ISpectifyLogger`).
  /// - `observer`: Optional observer instance for event tracking.
  /// - `options`: Custom options for configuration.
  /// - `filter`: Optional filter instance for log filtering.
  ///
  /// ### Example:
  /// ```dart
  /// final inspector = ISpectFlutter.init();
  /// inspector.log('Hello, ISpectify!');
  /// ```
  ///
  /// Returns:
  /// A configured instance of `ISpectify` with adapted logging.
  static ISpectLogger init({
    ISpectBaseLogger? logger,
    ISpectObserver? observer,
    ISpectLoggerOptions? options,
    ISpectFilter? filter,
    ILogHistory? history,
  }) =>
      ISpectLogger(
        logger: (logger ?? ISpectBaseLogger()).copyWith(
          output: _defaultFlutterOutput,
        ),
        options: options,
        observer: observer,
        filter: filter,
        history: history,
      );

  /// Default output handler for logging in Flutter.
  ///
  /// This method determines the appropriate logging mechanism based on
  /// the platform:
  /// - **Web**: Uses `print()`.
  /// - **iOS/macOS**: Uses `log()` for structured logging.
  /// - **Other platforms**: Uses `debugPrint()` for efficient log handling.
  ///
  /// - `message`: The log message to be displayed.
  static void _defaultFlutterOutput(String message) {
    if (kIsWeb) {
      // Web environments use print as the default logging mechanism.
      // ignore: avoid_print
      print(message);
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        log(message, name: 'ISpect', level: 1000);
      default:
        // ignore: avoid_print
        print(message);
    }
  }
}
