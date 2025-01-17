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
}
