import 'package:ispectify/ispectify.dart';

/// Utility extensions on [ISpectLogData]: copy, formatting, cURL generation.
extension ISpectDataX on ISpectLogData {
  ISpectLogData copyWith({
    Object? message,
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

  ISpectLogData copy() => copyWith();

  /// Truncated summary for debugging/display.
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

  /// Stack trace text for log display. Returns `null` if unavailable.
  String? get stackTraceLogText {
    if (isError && stackTrace != null && stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n$stackTrace'.truncate();
    }
    return null;
  }

  /// Error/exception message with special handling for HTTP and Flutter errors.
  String? get httpLogText {
    var txt = exception?.toString();

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', ' ')}';
    }

    final text = isHttpLog ? textMessage : txt;

    return text.truncate();
  }

  bool get isHttpLog =>
      key == ISpectLogType.httpRequest.key ||
      key == ISpectLogType.httpResponse.key ||
      key == ISpectLogType.httpError.key;

  bool get isRouteLog => key == ISpectLogType.route.key;

  /// Generates a cURL command for HTTP logs, or `null` for non-HTTP entries.
  String? get curlCommand {
    if (key == ISpectLogType.httpRequest.key) {
      return CurlUtils.generateCurl(additionalData);
    } else if (key == ISpectLogType.httpResponse.key ||
        key == ISpectLogType.httpError.key) {
      final requestOptions =
          additionalData?['request-options'] as Map<String, dynamic>?;
      return requestOptions != null
          ? CurlUtils.generateCurl(requestOptions)
          : null;
    }
    return null;
  }

  /// Exception/error runtime type label, or `null` for non-error logs.
  String? get typeText {
    if (this is! ISpectLogError && this is! ISpectLogException) {
      return null;
    }
    return 'Type: ${exception?.runtimeType ?? error?.runtimeType ?? ''}';
  }
}
