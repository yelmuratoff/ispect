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
        if (key != null) 'key': key,
        'time': time.toIso8601String(),
        if (title != null)
          'title': truncated && title != null ? title.truncate() : title,
        if (logLevel != null) 'log-level': logLevel?.index.toString(),
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
  /// Note: AnsiPen, Exception, Error, and StackTrace are reconstructed
  /// from string representations with some limitations.
  static ISpectLogData fromJson(Map<String, dynamic> json) => ISpectLogData(
        json['message'] as String?,
        time: DateTime.parse(json['time'] as String),
        logLevel: json['log-level'] != null
            ? LogLevel.values[int.parse(json['log-level'] as String)]
            : null,
        title: json['title'] as String?,
        key: json['key'] as String?,
        additionalData: json['additional-data'] as Map<String, dynamic>?,
        // Note: These are reconstructed as strings for JSON compatibility
        exception: json['exception'] != null
            ? _StringException(json['exception'] as String)
            : null,
        error: json['error'] != null
            ? _StringError(json['error'] as String)
            : null,
        stackTrace: json['stack-trace'] != null
            ? StackTrace.fromString(json['stack-trace'] as String)
            : null,
      );
}

/// Helper class to represent exceptions deserialized from JSON.
class _StringException implements Exception {
  const _StringException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Helper class to represent errors deserialized from JSON.
class _StringError extends Error {
  _StringError(this.message);

  final String message;

  @override
  String toString() => message;
}
