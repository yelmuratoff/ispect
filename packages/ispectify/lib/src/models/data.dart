import 'package:ispectify/ispectify.dart';

/// A model class representing a structured log entry.
class ISpectifyData {
  /// Creates an instance of [ISpectifyData] to store log details.
  ///
  /// - [message]: The main log message.
  /// - [time]: The timestamp of the log entry. Defaults to [DateTime.now()].
  /// - [logLevel]: The severity level of the log.
  /// - [exception]: Any associated exception.
  /// - [error]: Any associated error.
  /// - [stackTrace]: The stack trace for debugging.
  /// - [title]: An optional title for categorizing logs.
  /// - [pen]: ANSI color for styling logs.
  /// - [key]: A unique identifier for this log entry.
  /// - [additionalData]: Any extra metadata attached to the log.
  ISpectifyData(
    this.message, {
    DateTime? time,
    this.logLevel,
    this.exception,
    this.error,
    this.stackTrace,
    this.title,
    this.pen,
    this.key,
    this.additionalData,
  }) : _time = time ?? DateTime.now();

  /// The timestamp when the log entry was created.
  final DateTime _time;

  /// A unique identifier for the log entry.
  final String? key;

  /// The main log message.
  final String? message;

  /// The severity level of the log entry.
  final LogLevel? logLevel;

  /// An optional title for categorizing the log.
  final String? title;

  /// ANSI color styling for the log message.
  final AnsiPen? pen;

  /// Additional metadata associated with the log entry.
  final Map<String, dynamic>? additionalData;

  /// Any exception associated with the log entry.
  final Object? exception;

  /// Any error associated with the log entry.
  final Error? error;

  /// The stack trace associated with the log entry.
  final StackTrace? stackTrace;

  /// Returns the timestamp of the log.
  DateTime get time => _time;

  /// Returns the full message, including the stack trace if available.
  String get textMessage {
    final errMsg = (error != null)
        ? '$error'.truncated
        : ((exception != null) ? '$exception' : ''.truncated);

    return '$messageText$errMsg$stackTraceText';
  }

  /// Returns a formatted log header including the title or key and timestamp.
  String get header => '[${title ?? key}] | $formattedTime\n';

  /// Returns the formatted stack trace if available, otherwise an empty string.
  String get stackTraceText =>
      (stackTrace != null && stackTrace != StackTrace.empty)
          ? '\nStackTrace: $stackTrace'
          : '';

  /// Returns the exception as a string if available, otherwise an empty string.
  String? get exceptionText =>
      exception != null ? '\n$exception'.truncated : '';

  /// Returns the error as a string if available, otherwise an empty string.
  String? get errorText => error != null ? '\n$error'.truncated : '';

  /// Returns the log message as a string, or an empty string if `null`.
  String? get messageText => message.truncated;

  /// Returns the formatted timestamp of the log entry.
  String get formattedTime => ISpectifyDateTimeFormatter(time).format;
}
