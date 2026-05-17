import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';
import 'package:ispectify/src/models/log_id.dart';
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
    String? id,
  })  : id = id ?? LogId.generate(),
        message = message?.toString(),
        additionalData = additionalData == null
            ? null
            : Map<String, dynamic>.unmodifiable(
                Map<String, dynamic>.from(additionalData),
              ),
        time = time ?? DateTime.now();

  /// ULID-style identifier — globally unique across processes, isolates, and
  /// reloaded log files. Lexicographically sortable by creation time.
  ///
  /// Pass an explicit [id] when reconstructing entries from persisted JSON to
  /// preserve the original identity; otherwise a fresh ULID is generated.
  final String id;

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
  /// Retained for backward compatibility. Prefer
  /// `HumanLogEntryFormatter` / `JsonLogEntryFormatter` via
  /// `ConsoleSettings.format` — they see the full entry context
  /// (source, correlation IDs, duration) and know about
  /// [ConsoleSettings.fullTimestamp].
  ///
  /// Format: `LEVEL   [key] | HH:MM:SS.mmm | `
  ///
  /// - `LEVEL` is the canonical severity label (`INFO`, `ERROR`, …) so the
  ///   output is grep-friendly and aligned with industry log conventions.
  ///   Right-padded to [_levelColumnWidth] so levels align in a visual column;
  ///   `CRITICAL` overflows by one character — acceptable since critical logs
  ///   are rare and should stand out anyway.
  /// - `[key]` is the log category/type (e.g. `route`, `httpResponse`) and is
  ///   omitted when it is redundant with the level (either equal to it, or
  ///   when the level was implicitly derived from the key).
  /// - No trailing newline: the message follows inline so each log entry
  ///   occupies a single line (multi-line payloads keep their own newlines).
  String get header {
    final explicitLevel = logLevel?.name;
    final levelFromKey = _levelFromKey(key);
    final levelLabel = (explicitLevel ?? levelFromKey ?? 'log').toUpperCase();
    final paddedLevel = levelLabel.padRight(_levelColumnWidth);
    final keyIsLevel =
        key != null && (key == explicitLevel || key == levelFromKey);
    final keyLabel = key != null && !keyIsLevel ? ' [$key]' : '';
    return '$paddedLevel$keyLabel | $formattedTime | ';
  }

  /// Width of the level column in [header] output.
  ///
  /// Chosen as `7` to fit `WARNING`/`VERBOSE` exactly and leave `INFO`/`DEBUG`/
  /// `ERROR` with consistent right-padding, trading a one-character overflow
  /// on `CRITICAL` for tighter columns in the 99% case.
  static const int _levelColumnWidth = 7;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ISpectLogData && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '''ISpectLogData(
      key: $key,
      message: ${message.truncate()},
      logLevel: $logLevel,
      exception: ${exception?.toString().truncate()},
      error: ${error?.toString().truncate()},
      )''';
}
