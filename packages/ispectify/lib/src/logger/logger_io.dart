import 'package:ispectify/src/models/log_level.dart';

// ignore_for_file: avoid_print

/// Prints each line of [message] to stdout.
void outputLog(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) =>
    message.split('\n').forEach(print);
