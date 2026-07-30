import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';
import 'package:ispectify/src/models/log_id.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart'
    as placeholders;
import 'package:ispectify/src/utils/safe_object_description.dart';
import 'package:meta/meta.dart';

DiagnosticResourceLimits _validatedResourceLimits(
  DiagnosticResourceLimits resourceLimits,
) {
  resourceLimits.validate();
  return resourceLimits;
}

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
    LogLevel? logLevel,
    Object? exception,
    Error? error,
    StackTrace? stackTrace,
    AnsiPen? pen,
    String? key,
    Map<String, dynamic>? additionalData,
    String? id,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  })  : _id = id ?? LogId.generate(),
        _captureMode = captureMode,
        _resourceLimits = _validatedResourceLimits(resourceLimits),
        _time = _captureTime(time),
        _key = key,
        _messageCapture = _captureMessage(message, captureMode, resourceLimits),
        _logLevel = logLevel,
        _pen = pen,
        _additionalData = _captureAdditionalData(
          additionalData,
          captureMode,
          resourceLimits,
        ),
        _exception = exception,
        _exceptionSnapshot = _captureDiagnostic(
          exception,
          captureMode,
          resourceLimits,
        ),
        _error = error,
        _errorSnapshot = _captureDiagnostic(error, captureMode, resourceLimits),
        _stackTrace = stackTrace,
        _stackTraceSnapshot = _captureStackTrace(
          stackTrace,
          captureMode,
          resourceLimits,
        );

  /// ULID-style identifier — globally unique across processes, isolates, and
  /// reloaded log files. Lexicographically sortable by creation time.
  ///
  /// Pass an explicit [id] when reconstructing entries from persisted JSON to
  /// preserve the original identity; otherwise a fresh ULID is generated.
  final String _id;
  final DiagnosticCaptureMode _captureMode;
  final DiagnosticResourceLimits _resourceLimits;
  final DateTime _time;
  final String? _key;
  final _MessageCapture _messageCapture;
  final LogLevel? _logLevel;
  final AnsiPen? _pen;
  final Map<String, dynamic>? _additionalData;
  final Object? _exception;
  final String? _exceptionSnapshot;
  final Error? _error;
  final String? _errorSnapshot;
  final StackTrace? _stackTrace;
  final String? _stackTraceSnapshot;

  String get id => _id;

  DateTime get time => _time;

  String? get key => _key;

  LogLevel? get logLevel => _logLevel;

  AnsiPen? get pen => _pen;

  Map<String, dynamic>? get additionalData => _additionalData;

  Object? get exception => _exception;

  Error? get error => _error;

  StackTrace? get stackTrace => _stackTrace;

  String? get message => _messageCapture.text;

  /// Capture representation retained so binary provenance survives a later
  /// redaction-mode change before export.
  @internal
  Object? get messageForSerialization => _messageCapture.serialization;

  /// Cached lowercase message for efficient repeated case-insensitive search.
  String? get lowerMessage => _lowerMessage;

  late final String? _lowerMessage = _messageCapture.text?.toLowerCase();

  /// Full message including error/exception and stack trace.
  String get textMessage => _textMessage;

  late final String _textMessage = joinLogParts([
    _messageText,
    _errorText,
    _exceptionText,
    _stackTraceText,
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
    final explicitLevel = _logLevel?.name;
    final levelFromKey = _levelFromKey(_key);
    final levelLabel = (explicitLevel ?? levelFromKey ?? 'log').toUpperCase();
    final paddedLevel = levelLabel.padRight(_levelColumnWidth);
    final keyIsLevel =
        _key != null && (_key == explicitLevel || _key == levelFromKey);
    final keyLabel = _key != null && !keyIsLevel ? ' [$_key]' : '';
    return '$paddedLevel$keyLabel | $_formattedTime | ';
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

  String? get stackTraceText => _stackTraceText;

  String? get exceptionText => _exceptionText;

  String? get errorText => _errorText;

  String get messageText => _messageText;

  String get formattedTime => _formattedTime;

  late final String _formattedTime =
      ISpectDateTimeFormatter(_time).defaultFormat;

  bool get isError => _isError;

  /// Dispatches to the appropriate [ISpectObserver] callback.
  /// Subclasses override to route to `onException` etc.
  void notifyObserver(ISpectObserver observer) {
    if (_isError) {
      observer.onError(this);
    } else {
      observer.onLog(this);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ISpectLogData && other._id == _id);

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => '''ISpectLogData(
      key: $_key,
      message: ${_messageCapture.text.truncate()},
      logLevel: ${_logLevel?.name},
      exception: ${_exceptionSnapshot.truncate()},
      error: ${_errorSnapshot.truncate()},
      )''';

  String get _messageText => _messageCapture.text ?? '';

  String? get _exceptionText => _exceptionSnapshot;

  String? get _errorText => _errorSnapshot;

  String? get _stackTraceText {
    if (_stackTrace == null || identical(_stackTrace, StackTrace.empty)) {
      return null;
    }
    final text = _stackTraceSnapshot;
    return text == null ? null : 'StackTrace: $text';
  }

  bool get _isError =>
      _logLevel == LogLevel.error ||
      _logLevel == LogLevel.critical ||
      ISpectLogType.isErrorKey(_key) ||
      _additionalData?[TraceKeys.success] == false;
}

/// Reads the package-owned base storage without dispatching through getters
/// that an external subtype can override.
({
  String id,
  DiagnosticCaptureMode captureMode,
  DiagnosticResourceLimits resourceLimits,
  DateTime time,
  String? key,
  Object? message,
  LogLevel? logLevel,
  AnsiPen? pen,
  Map<String, dynamic>? additionalData,
  Object? exception,
  String? exceptionText,
  Error? error,
  String? errorText,
  StackTrace? stackTrace,
  String? stackTraceText,
}) captureISpectLogDataForEgress(ISpectLogData data) => (
      id: data._id,
      captureMode: data._captureMode,
      resourceLimits: data._resourceLimits,
      time: data._time,
      key: data._key,
      message: data._messageCapture.serialization,
      logLevel: data._logLevel,
      pen: data._pen,
      additionalData: data._additionalData,
      exception: data._exception == null
          ? null
          : _CapturedException(
              data._exceptionSnapshot ?? JsonValueNormalizer.unprintableValue,
            ),
      exceptionText: data._exceptionSnapshot,
      error: data._error == null
          ? null
          : _CapturedError(
              data._errorSnapshot ?? JsonValueNormalizer.unprintableValue,
            ),
      errorText: data._errorSnapshot,
      stackTrace: data._stackTrace == null
          ? null
          : identical(data._stackTrace, StackTrace.empty)
              ? StackTrace.empty
              : _CapturedStackTrace(
                  data._stackTraceSnapshot ??
                      JsonValueNormalizer.unprintableValue,
                ),
      stackTraceText: data._stackTraceSnapshot,
    );

String? _captureDiagnostic(
  Object? value,
  DiagnosticCaptureMode captureMode,
  DiagnosticResourceLimits resourceLimits,
) {
  if (value == null) return null;
  final binaryByteLength = _binaryByteLength(value);
  if (binaryByteLength != null) {
    return placeholders.binaryPlaceholder(binaryByteLength);
  }
  final description = switch (value) {
    _CapturedException(:final text) => text,
    _CapturedError(:final text) => text,
    _CapturedStackTrace(:final text) => text,
    _ when captureMode == DiagnosticCaptureMode.balanced =>
      _guardedDiagnosticText(value),
    _ => safeDiagnosticDescriptor(value),
  };
  return _boundDiagnosticText(description, resourceLimits);
}

typedef _MessageCapture = ({String? text, Object? serialization});

String? _captureStackTrace(
  StackTrace? value,
  DiagnosticCaptureMode captureMode,
  DiagnosticResourceLimits resourceLimits,
) {
  if (value == null) return null;
  if (value case _CapturedStackTrace(:final text)) return text;
  final captured = captureMode == DiagnosticCaptureMode.balanced
      ? _guardedDiagnosticText(value)
      : JsonValueNormalizer.unprintableValue;
  return _boundDiagnosticText(captured, resourceLimits);
}

final class _CapturedException implements Exception {
  const _CapturedException(this.text);

  final String text;

  @override
  String toString() => text;
}

final class _CapturedError extends Error {
  _CapturedError(this.text);

  final String text;

  @override
  StackTrace get stackTrace => StackTrace.empty;

  @override
  String toString() => text;
}

final class _CapturedStackTrace implements StackTrace {
  const _CapturedStackTrace(this.text);

  final String text;

  @override
  String toString() => text;
}

DateTime _captureTime(DateTime? value) {
  if (value == null) return DateTime.now();
  try {
    return DateTime.fromMicrosecondsSinceEpoch(
      value.microsecondsSinceEpoch,
      isUtc: value.isUtc,
    );
  } catch (_) {
    return DateTime.now();
  }
}

Map<String, dynamic>? _captureAdditionalData(
  Map<String, dynamic>? value,
  DiagnosticCaptureMode captureMode,
  DiagnosticResourceLimits resourceLimits,
) {
  if (value == null) return null;
  final bounded = LogExportOutput.boundJsonValue(
    value,
    resourceLimits: resourceLimits,
    preserveTypes: true,
    replaceOversizedStrings: ISpectRedaction.enabled,
    allowCustomSerialization: captureMode == DiagnosticCaptureMode.balanced,
    allowCustomStringification: captureMode == DiagnosticCaptureMode.balanced,
  );
  if (bounded is! Map<String, Object?>) return const {};
  return _freezeCapturedMap(bounded);
}

_MessageCapture _captureMessage(
  Object? value,
  DiagnosticCaptureMode captureMode,
  DiagnosticResourceLimits resourceLimits,
) {
  if (value == null) return (text: null, serialization: null);
  final byteLength = _binaryByteLength(value);
  if (byteLength != null) {
    final placeholder = placeholders.binaryPlaceholder(byteLength);
    return (
      text: placeholder,
      serialization: ISpectRedaction.enabled ||
              byteLength > resourceLimits.maxCapturedValueBytes
          ? placeholder
          : _freezeCapturedValue(value),
    );
  }

  final capturedText = captureMode == DiagnosticCaptureMode.balanced
      ? _guardedDiagnosticText(value)
      : safeScalarText(value) ?? JsonValueNormalizer.unprintableValue;
  final text = _boundDiagnosticText(capturedText, resourceLimits);
  return (text: text, serialization: text);
}

String _guardedDiagnosticText(Object value) {
  try {
    return value.toString();
  } on Object {
    return JsonValueNormalizer.unprintableValue;
  }
}

String _boundDiagnosticText(
  String value,
  DiagnosticResourceLimits resourceLimits,
) =>
    LogExportOutput.truncateUtf8(
      value,
      maxBytes: resourceLimits.maxCapturedValueBytes,
    );

Map<String, dynamic> _freezeCapturedMap(Map<String, Object?> value) {
  final frozen = <String, Object?>{
    for (final entry in value.entries)
      entry.key: _freezeCapturedValue(entry.value),
  };
  return Map<String, dynamic>.unmodifiable(frozen);
}

Object? _freezeCapturedValue(Object? value) => switch (value) {
      final ByteBuffer buffer => _copyByteBuffer(buffer),
      final ByteData data =>
        _copyTypedDataBytes(data).buffer.asByteData().asUnmodifiableView(),
      final Int8List data =>
        _copyTypedDataBytes(data).buffer.asInt8List().asUnmodifiableView(),
      final Uint8List data =>
        _copyTypedDataBytes(data).buffer.asUint8List().asUnmodifiableView(),
      final Uint8ClampedList data => _copyTypedDataBytes(data)
          .buffer
          .asUint8ClampedList()
          .asUnmodifiableView(),
      final Int16List data =>
        _copyTypedDataBytes(data).buffer.asInt16List().asUnmodifiableView(),
      final Uint16List data =>
        _copyTypedDataBytes(data).buffer.asUint16List().asUnmodifiableView(),
      final Int32List data =>
        _copyTypedDataBytes(data).buffer.asInt32List().asUnmodifiableView(),
      final Uint32List data =>
        _copyTypedDataBytes(data).buffer.asUint32List().asUnmodifiableView(),
      final Int64List data =>
        _copyTypedDataBytes(data).buffer.asInt64List().asUnmodifiableView(),
      final Uint64List data =>
        _copyTypedDataBytes(data).buffer.asUint64List().asUnmodifiableView(),
      final Float32List data =>
        _copyTypedDataBytes(data).buffer.asFloat32List().asUnmodifiableView(),
      final Float64List data =>
        _copyTypedDataBytes(data).buffer.asFloat64List().asUnmodifiableView(),
      final Float32x4List data =>
        _copyTypedDataBytes(data).buffer.asFloat32x4List().asUnmodifiableView(),
      final Int32x4List data =>
        _copyTypedDataBytes(data).buffer.asInt32x4List().asUnmodifiableView(),
      final Float64x2List data =>
        _copyTypedDataBytes(data).buffer.asFloat64x2List().asUnmodifiableView(),
      final TypedData data => _copyTypedDataBytes(data).asUnmodifiableView(),
      final Map<String, Object?> map => _freezeCapturedMap(map),
      final List<Object?> list => List<Object?>.unmodifiable(
          list.map(_freezeCapturedValue),
        ),
      _ => value,
    };

ByteBuffer _copyByteBuffer(ByteBuffer value) =>
    Uint8List.fromList(value.asUint8List()).asUnmodifiableView().buffer;

Uint8List _copyTypedDataBytes(TypedData value) => Uint8List.fromList(
      value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes),
    );

int? _binaryByteLength(Object? value) {
  try {
    return switch (value) {
      final ByteBuffer buffer => buffer.lengthInBytes,
      final TypedData data => data.lengthInBytes,
      _ => null,
    };
  } catch (_) {
    return null;
  }
}
