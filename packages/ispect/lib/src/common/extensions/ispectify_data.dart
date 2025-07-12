import 'package:ispectify/ispectify.dart';

/// Extension on `ISpectifyData` for additional functionalities.
///
/// Provides utility methods to manipulate and format log data efficiently.
extension ISpectDataX on ISpectifyData {
  /// Returns a copy of this `ISpectifyData` with optional new values.
  ///
  /// If no parameters are provided, the original values are retained.
  ISpectifyData copyWith({
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
      ISpectifyData(
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

  /// Creates an exact duplicate of this `ISpectifyData` instance.
  ISpectifyData copy() => copyWith();

  /// Generates a formatted summary text for logging.
  ///
  /// Limits text length to avoid overly long logs.
  String generateText() {
    String truncate(String? value, int maxLength) {
      if (value == null) return '';
      return value.length > maxLength
          ? '${value.substring(0, maxLength)}...'
          : value;
    }

    final formattedTitle = truncate(title, 100);
    final formattedMessage = truncate(message, 100);
    final exceptionText = truncate(exception?.toString(), 500);
    final errorText = truncate(error?.toString(), 500);
    final stackTraceText = truncate(stackTrace?.toString(), 500);

    return '''[Item with hashcode: $hashCode
Time: $formattedTime
Title: $formattedTitle
Message: $formattedMessage
Exception: $exceptionText
Error: $errorText
StackTrace: $stackTraceText]''';
  }

  /// Extracts stack trace text for logging.
  ///
  /// Returns `null` if no valid stack trace is available.
  String? get stackTraceLogText {
    if ((this is ISpectifyError ||
            this is ISpectifyException ||
            message == 'FlutterErrorDetails') &&
        stackTrace != null &&
        stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n$stackTrace'.truncated;
    }
    return null;
  }

  /// Extracts the error message for logging.
  ///
  /// Special handling for HTTP logs and Flutter error details.
  String? get httpLogText {
    var txt = exception?.toString();

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', ' ')}';
    }

    final text = isHttpLog ? textMessage : txt;

    return text.truncated;
  }

  /// Checks if this log entry is related to HTTP requests.
  bool get isHttpLog => [
        ISpectifyLogType.httpRequest.key,
        ISpectifyLogType.httpResponse.key,
        ISpectifyLogType.httpError.key,
      ].contains(key);

  bool get isRouteLog => key == ISpectifyLogType.route.key;

  /// Retrieves the type of exception or error, if applicable.
  ///
  /// Returns `null` for non-error logs.
  String? get typeText {
    if (this is! ISpectifyError && this is! ISpectifyException) return null;
    return 'Type: ${exception?.runtimeType ?? error?.runtimeType ?? ''}';
  }

  // /// Converts the log data into a JSON representation.
  // ///
  // /// Omits `null` values for a cleaner output.
  // Map<String, dynamic> toJson({
  //   bool truncated = false,
  // }) =>
  //     {
  //       if (key != null) 'key': key,
  //       'time': time.toIso8601String(),
  //       if (title != null)
  //         'title': truncated && title != null ? title.truncated : title,
  //       if (logLevel != null) 'log-level': logLevel.toString(),
  //       if (message != null) 'message': truncated ? message.truncated : message,
  //       if (exception != null)
  //         'exception':
  //             truncated ? exception.toString().truncated : exception.toString(),
  //       if (error != null)
  //         'error': truncated ? error.toString().truncated : error.toString(),
  //       if (stackTrace != null)
  //         'stack-trace': truncated
  //             ? stackTrace.toString().truncated
  //             : stackTrace.toString(),
  //       if (additionalData != null) 'additional-data': additionalData,
  //     };
}
