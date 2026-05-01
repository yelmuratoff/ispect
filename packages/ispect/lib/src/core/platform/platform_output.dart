import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Platform-aware output utility to centralize platform detection logic.
///
/// Business logic should call [PlatformOutput.log] instead of branching
/// on `kIsWeb` or `defaultTargetPlatform` directly.
final class PlatformOutput {
  const PlatformOutput._();

  /// Writes a log message using the most appropriate platform mechanism.
  static void log(
    String message, {
    int level = 0,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    if (kIsWeb) {
      // ignore: avoid_print
      print(message);
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        developer.log(
          message,
          name: 'ISpect',
          level: level,
          error: error,
          stackTrace: stackTrace,
          time: time,
        );
      default:
        // ignore: avoid_print
        print(message);
    }
  }
}
