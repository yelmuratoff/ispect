import 'package:talker_flutter/talker_flutter.dart';

extension ISpectTalkerDataX on TalkerData {
  TalkerData copyWith({
    String? message,
    LogLevel? logLevel,
    Object? exception,
    Error? error,
    String? title,
    StackTrace? stackTrace,
    DateTime? time,
    AnsiPen? pen,
    String? key,
  }) =>
      TalkerData(
        message ?? this.message,
        logLevel: logLevel ?? this.logLevel,
        exception: exception ?? this.exception,
        error: error ?? this.error,
        title: title ?? this.title,
        stackTrace: stackTrace ?? this.stackTrace,
        time: time ?? this.time,
        pen: pen ?? this.pen,
        key: key ?? this.key,
      );

  TalkerData copy() => TalkerData(
        message,
        logLevel: logLevel,
        exception: exception,
        error: error,
        title: title,
        stackTrace: stackTrace,
        time: time,
        pen: pen,
        key: key,
      );
}
