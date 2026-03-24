import 'dart:js_interop';

import 'package:ispectify/src/models/log_level.dart';
import 'package:web/web.dart';

/// Logs each line of [message] to the browser console.
void outputLog(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    message.split('\n').forEach(
          (line) => console.log(line.toJS),
        );
