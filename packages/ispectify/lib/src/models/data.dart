// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
import 'package:collection/collection.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';
// TraceKeys is available via ispectify.dart barrel export.

/// Core log entry model. All fields are immutable after construction.
class ISpectLogData {
  ISpectLogData(
    Object? message, {
    DateTime? time,
    this.logLevel,
    this.exception,
    this.error,
    this.stackTrace,
    this.title,
    this.pen,
    this.key,
    Map<String, dynamic>? additionalData,
  })  : id = _nextId++,
        message = message?.toString(),
        additionalData = additionalData == null
            ? null
            : Map<String, dynamic>.unmodifiable(
                Map<String, dynamic>.from(additionalData),
              ),
        time = time ?? DateTime.now();

  static int _nextId = 0;

  /// Auto-incrementing identifier, unique per isolate.
  final int id;

  final DateTime time;
  final String? key;
  final String? message;
  final LogLevel? logLevel;
  final String? title;
  final AnsiPen? pen;
  final Map<String, dynamic>? additionalData;
  final Object? exception;
  final Error? error;
  final StackTrace? stackTrace;

  /// Cached lowercase message for efficient repeated case-insensitive search.
  late final String? lowerMessage = message?.toLowerCase();

  /// Full message including error/exception and stack trace.
  late final String textMessage = joinLogParts([
    messageText,
    errorText,
    exceptionText,
    stackTraceText,
  ]);

  String get header => '[${title ?? key}] | $formattedTime\n';

  String? get stackTraceText =>
      (stackTrace != null && stackTrace != StackTrace.empty)
          ? 'StackTrace: $stackTrace'.truncate()
          : null;

  String? get exceptionText => exception?.toString().truncate();

  String? get errorText => error?.toString().truncate();

  String get messageText => message.truncate() ?? '';

  late final String formattedTime = ISpectDateTimeFormatter(time).defaultFormat;

  bool get isError =>
      logLevel == LogLevel.error ||
      logLevel == LogLevel.critical ||
      ISpectLogType.isErrorKey(key) ||
      additionalData?[TraceKeys.success] == false;

  /// Dispatches to the appropriate [ISpectObserver] callback.
  /// Subclasses override to route to `onException` etc.
  void notifyObserver(ISpectObserver observer) {
    if (isError) {
      observer.onError(this);
    } else {
      observer.onLog(this);
    }
  }

  static const _deepEquality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectLogData &&
        other.time == time &&
        other.key == key &&
        other.message == message &&
        other.logLevel == logLevel &&
        other.title == title &&
        other.pen == pen &&
        _deepEquality.equals(other.additionalData, additionalData) &&
        other.exception == exception &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(
        time,
        key,
        message,
        logLevel,
        title,
        pen,
        _deepEquality.hash(additionalData),
        exception,
        error,
        stackTrace,
      );

  @override
  String toString() => '''ISpectLogData(
      key: $key,
      message: ${message.truncate()},
      logLevel: $logLevel,
      title: $title,
      exception: ${exception?.toString().truncate()},
      error: ${error?.toString().truncate()},
      )''';
}
