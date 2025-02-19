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
    this.data,
  }) {
    _time = time ?? DateTime.now();
  }

  late DateTime _time;

  final String? key;
  final String? message;
  final LogLevel? logLevel;
  final String? title;
  final AnsiPen? pen;
  final Map<String, dynamic>? data;

  final Object? exception;
  final Error? error;
  final StackTrace? stackTrace;

  DateTime get time => _time;

  String get textMessage => '$message$stackTraceText';

  String get header => '[${title ?? key}] | $formattedTime\n';

  String get stackTraceText {
    if (stackTrace == null || stackTrace == StackTrace.empty) {
      return '';
    }
    return '\nStackTrace: $stackTrace}';
  }

  String? get stackTraceLogText {
    if ((this is ISpectifyError || this is ISpectifyException || message == 'FlutterErrorDetails') &&
        stackTrace != null &&
        stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n$stackTrace';
    }
    return null;
  }

  String? get errorLogText {
    var txt = exception?.toString();

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', '')}';
    }

    if (isHttpLog) {
      return textMessage;
    }
    return txt;
  }

  String? get typeText {
    if (this is! ISpectifyError && this is! ISpectifyException) {
      return null;
    }
    return 'Type: ${exception?.runtimeType.toString() ?? error?.runtimeType.toString() ?? ''}';
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

  bool get isHttpLog => [
        ISpectifyLogType.httpRequest.key,
        ISpectifyLogType.httpResponse.key,
        ISpectifyLogType.httpError.key,
      ].contains(key);
}
