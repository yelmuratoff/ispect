import 'package:ispectify/ispectify.dart';

/// Extension for ISpectLogData to add JSON serialization support.
extension ISpectLogDataSerialization on ISpectLogData {
  /// Converts the log data into a JSON representation.
  ///
  /// Omits `null` values for a cleaner output.
  Map<String, dynamic> toJson({
    bool truncated = false,
  }) =>
      {
        'id': id,
        if (key != null) 'key': key,
        'time': time.toIso8601String(),
        if (title != null)
          'title': truncated ? title.truncate() : title,
        if (logLevel != null) 'log-level': logLevel!.index.toString(),
        if (message != null)
          'message': truncated ? message.truncate() : message,
        if (exception != null)
          'exception': truncated
              ? exception.toString().truncate()
              : exception.toString(),
        if (error != null)
          'error': truncated ? error.toString().truncate() : error.toString(),
        if (stackTrace != null)
          'stack-trace': truncated
              ? stackTrace.toString().truncate()
              : stackTrace.toString(),
        if (additionalData != null) 'additional-data': additionalData,
      };
}

/// Utility class for ISpectLogData JSON operations.
class ISpectLogDataJsonUtils {
  /// Creates ISpectLogData from JSON Map.
  ///
  /// Throws [FormatException] if the JSON is missing required fields
  /// (`message` or `time`).
  ///
  /// Note: AnsiPen, Exception, Error, and StackTrace are reconstructed
  /// from string representations with some limitations.
  static ISpectLogData fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('message') && !json.containsKey('time')) {
      throw const FormatException(
        'Invalid log entry: missing both "message" and "time" fields',
      );
    }

    return ISpectLogData(
      json['message']?.toString(),
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      logLevel: _parseLogLevel(json['log-level']?.toString()),
      title: json['title']?.toString(),
      key: json['key']?.toString(),
      additionalData: json['additional-data'] is Map<String, dynamic>
          ? json['additional-data'] as Map<String, dynamic>
          : null,
      // Note: These are reconstructed as strings for JSON compatibility
      exception: json['exception'] != null
          ? _StringException(json['exception'].toString())
          : null,
      error:
          json['error'] != null ? _StringError(json['error'].toString()) : null,
      stackTrace: json['stack-trace'] != null
          ? StackTrace.fromString(json['stack-trace'].toString())
          : null,
    );
  }
}

LogLevel? _parseLogLevel(String? value) {
  if (value == null) return null;
  final index = int.tryParse(value);
  if (index == null || index < 0 || index >= LogLevel.values.length) {
    return null;
  }
  return LogLevel.values[index];
}

/// Helper class to represent exceptions deserialized from JSON.
class _StringException implements Exception {
  const _StringException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Helper class to represent errors deserialized from JSON.
///
/// Overrides [stackTrace] with [StackTrace.empty] to avoid capturing a
/// spurious stack trace at construction time, since these are reconstructed
/// from serialized data and do not represent real throw sites.
class _StringError extends Error {
  _StringError(this.message);

  final String message;

  @override
  StackTrace get stackTrace => StackTrace.empty;

  @override
  String toString() => message;
}
