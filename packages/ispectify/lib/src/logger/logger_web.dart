import 'dart:js_interop';

import 'package:ispectify/src/models/log_level.dart';
import 'package:web/web.dart';

/// Logs [message] as one browser console event.
void outputLog(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    console.log(message.toJS);
