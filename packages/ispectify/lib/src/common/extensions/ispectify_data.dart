import 'package:ispectify/ispectify.dart';

/// Extension on `ISpectLogData` for additional functionalities.
///
/// Provides utility methods to manipulate and format log data efficiently.
extension ISpectDataX on ISpectLogData {
  /// Returns a copy of this `ISpectLogData` with optional new values.
  ///
  /// If no parameters are provided, the original values are retained.
  ISpectLogData copyWith({
    String? message,
    LogLevel? logLevel,
    Object? exception,
    Error? error,
    String? title,
    StackTrace? stackTrace,
    DateTime? time,
    AnsiPen? pen,
    String? key,
    Map<String, dynamic>? additionalData,
  }) =>
      ISpectLogData(
        message ?? this.message,
        logLevel: logLevel ?? this.logLevel,
        exception: exception ?? this.exception,
        error: error ?? this.error,
        title: title ?? this.title,
        stackTrace: stackTrace ?? this.stackTrace,
        time: time ?? this.time,
        pen: pen ?? this.pen,
        key: key ?? this.key,
        additionalData: additionalData ?? this.additionalData,
      );

  /// Creates an exact duplicate of this `ISpectLogData` instance.
  ISpectLogData copy() => copyWith();

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
    if (isError && stackTrace != null && stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n$stackTrace'.truncate();
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

    return text.truncate();
  }

  /// Checks if this log entry is related to HTTP requests.
  bool get isHttpLog => [
        ISpectLogType.httpRequest.key,
        ISpectLogType.httpResponse.key,
      ].contains(key);

  bool get isRouteLog => key == ISpectLogType.route.key;

  /// Generates a cURL command for HTTP logs (request, response, or error).
  ///
  /// Returns the cURL command as a string if the log contains HTTP request data,
  /// otherwise returns `null`.
  String? get curlCommand {
    if (key == ISpectLogType.httpRequest.key) {
      return CurlUtils.generateCurl(additionalData);
    } else if (key == ISpectLogType.httpResponse.key ||
        key == ISpectLogType.httpError.key) {
      // For response/error logs, extract request-options from additionalData
      final requestOptions =
          additionalData?['request-options'] as Map<String, dynamic>?;
      return requestOptions != null
          ? CurlUtils.generateCurl(requestOptions)
          : null;
    }
    return null;
  }

  /// Retrieves the type of exception or error, if applicable.
  ///
  /// Returns `null` for non-error logs.
  String? get typeText {
    if (this is! ISpectLogError && this is! ISpectLogException) {
      return null;
    }
    return 'Type: ${exception?.runtimeType ?? error?.runtimeType ?? ''}';
  }
}
