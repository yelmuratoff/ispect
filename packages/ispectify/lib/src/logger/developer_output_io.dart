import 'dart:developer' as developer;

import 'package:ispectify/src/models/log_level.dart';

/// Routes [message] to `dart:developer`'s `log()` as a single `ISpect`-tagged
/// entry, mapping [logLevel] to its developer-log level.
///
/// Opt-in alternative to the default stdout output. Pass it as
/// `ISpectBaseLogger(output: developerLogOutput)` to surface logs in the
/// DevTools logging view and IDE consoles that read `dart:developer`, instead
/// of `print`. The whole [message] goes through one `log()` call, so multi-line
/// boxed output stays intact. On web this falls back to the browser console.
///
/// [message] arrives already colored when `ConsoleSettings.enableColors` is on;
/// pair with `enableColors: false` for viewers that render ANSI codes as raw
/// escape sequences instead of color.
void developerLogOutput(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    developer.log(
      message,
      name: 'ISpect',
      level: logLevel?.developerLevel ?? 0,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
