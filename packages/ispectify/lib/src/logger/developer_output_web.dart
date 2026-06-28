import 'dart:js_interop';

import 'package:ispectify/src/models/log_level.dart';
import 'package:web/web.dart';

/// Web fallback for `developerLogOutput`: logs each line of [message] to the
/// browser console, since `dart:developer` is not the surfaced channel on web.
void developerLogOutput(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    message.split('\n').forEach(
          (line) => console.log(line.toJS),
        );
