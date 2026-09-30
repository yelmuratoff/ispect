import 'package:ispectify/src/models/log_level.dart';

// ignore_for_file: avoid_print

/// Prints [message] as one stdout event.
void outputLog(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    print(message);
