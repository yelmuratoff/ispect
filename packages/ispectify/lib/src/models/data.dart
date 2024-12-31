import 'dart:ui';

import 'package:ispectify/ispectify.dart';

class ISpectiyData {
  ISpectiyData(
    this.message, {
    DateTime? time,
    this.logLevel,
    this.exception,
    this.error,
    this.stackTrace,
    this.title,
    this.pen,
    this.key,
    this.color,
  }) {
    _time = time ?? DateTime.now();
  }

  late DateTime _time;

  final String? key;
  final String? message;
  final LogLevel? logLevel;
  final String? title;
  final AnsiPen? pen;
  final Color? color;

  final Object? exception;
  final Error? error;
  final StackTrace? stackTrace;

  DateTime get time => _time;

  String get textMessage {
    return '$header$message$stackTraceText';
  }

  String get header {
    return '[$title] | $formattedTime\n';
  }

  String get stackTraceText {
    if (stackTrace == null || stackTrace == StackTrace.empty) {
      return '';
    }
    return '\nStackTrace: $stackTrace}';
  }

  String get exceptionText {
    if (exception == null) return '';

    return '\n$exception';
  }

  String get errorText {
    if (error == null) {
      return '';
    }
    return '\n$error';
  }

  String get messageText {
    if (message == null) {
      return '';
    }
    return '$message';
  }

  String get formattedTime => ISpectifyDateTimeFormatter(
        time,
      ).format;
}
