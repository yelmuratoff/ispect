import 'package:ispectify/ispectify.dart';

extension ISpectDataX on ISpectiyData {
  ISpectiyData copyWith({
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
      ISpectiyData(
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

  ISpectiyData copy() => ISpectiyData(
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

  String generateText() {
    final title = (this.title ?? '').length > 100
        ? '${this.title?.substring(0, 100)}...'
        : (this.title ?? '');
    final message = (this.message != null)
        ? this.message!.length > 100
            ? '${this.message?.substring(0, 100)}...'
            : this.message
        : '';
    var exceptionTitle = '';

    if (exception is Exception) {
      exceptionTitle = exception.toString();
    }
    exceptionTitle = exceptionTitle.length > 500
        ? '${exceptionTitle.substring(0, 500)}...'
        : exceptionTitle;
    final error = (this.error?.toString() ?? '').length > 500
        ? '${this.error.toString().substring(0, 500)}...'
        : (this.error?.toString() ?? '');
    final stackTrace = (this.stackTrace?.toString() ?? '').length > 500
        ? '${this.stackTrace.toString().substring(0, 500)}...'
        : (this.stackTrace?.toString() ?? '');

    return '''[Item with hashcode:$hashCode\nTime: $formattedTime\nTitle: $title\nMessage: $message\nException: $exceptionTitle\nError: $error\nStackTrace: $stackTrace]''';
  }

  String? get stackTraceLogText {
    if ((this is ISpectifyError ||
            this is ISpectifyException ||
            message == 'FlutterErrorDetails') &&
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

  bool get isHttpLog => [
        ISpectifyLogType.httpRequest.key,
        ISpectifyLogType.httpResponse.key,
        ISpectifyLogType.httpError.key,
      ].contains(key);

  String? get typeText {
    if (this is! ISpectifyError && this is! ISpectifyException) {
      return null;
    }
    return 'Type: ${exception?.runtimeType.toString() ?? error?.runtimeType.toString() ?? ''}';
  }

  Map<String, dynamic> toJson() => {
        if (key != null) 'key': key,
        'time': time.toIso8601String(),
        if (title != null) 'title': title,
        if (logLevel != null) 'log-level': logLevel,
        if (message != null) 'message': message,
        if (exception != null) 'exception': exception,
        if (error != null) 'error': error,
        if (stackTrace != null) 'stack-trace': stackTrace,
        if (additionalData != null) 'additional-data': additionalData,
      };
}
