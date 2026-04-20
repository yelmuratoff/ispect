import 'package:collection/collection.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';
import 'package:meta/meta.dart';

/// Core log entry model. All fields are immutable after construction.
///
/// Uses `base` modifier to prevent external `implements` while allowing
/// subclasses like [ISpectLogError], [ISpectLogException], and network log
/// types from interceptor packages.
@immutable
base class ISpectLogData {
  ISpectLogData(
    Object? message, {
    DateTime? time,
    this.logLevel,
    this.exception,
    this.error,
    this.stackTrace,
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

  /// Single-line header for console output.
  ///
  /// Format: `LEVEL [key] | HH:MM:SS.mmm | `
  ///
  /// - `LEVEL` is the canonical severity label (`INFO`, `ERROR`, …) so the
  ///   output is grep-friendly and aligned with industry log conventions.
  /// - `[key]` is the log category/type (e.g. `route`, `httpResponse`) and is
  ///   omitted when it is redundant with the level (either equal to it, or
  ///   when the level was implicitly derived from the key).
  /// - No trailing newline: the message follows inline so each log entry
  ///   occupies a single line (multi-line payloads keep their own newlines).
  String get header {
    final explicitLevel = logLevel?.name;
    final levelFromKey = _levelFromKey(key);
    final levelLabel = (explicitLevel ?? levelFromKey ?? 'log').toUpperCase();
    final keyIsLevel =
        key != null && (key == explicitLevel || key == levelFromKey);
    final keyLabel = key != null && !keyIsLevel ? ' [$key]' : '';
    return '$levelLabel$keyLabel | $formattedTime | ';
  }

  static const _keyToLevelNames = <String>{
    'critical',
    'error',
    'warning',
    'info',
    'debug',
    'verbose',
  };

  static String? _levelFromKey(String? key) =>
      key != null && _keyToLevelNames.contains(key) ? key : null;

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
        _deepEquality.equals(other.additionalData, additionalData) &&
        other.exception == exception &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  // [pen] excluded: presentation (console color), not content.
  @override
  int get hashCode => Object.hash(
        time,
        key,
        message,
        logLevel,
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
      exception: ${exception?.toString().truncate()},
      error: ${error?.toString().truncate()},
      )''';
}
