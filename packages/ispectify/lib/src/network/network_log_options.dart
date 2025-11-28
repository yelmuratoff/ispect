import 'package:ansicolor/ansicolor.dart';

/// Abstraction describing print preferences and color configuration for
/// network-related logs.
///
/// Packages implementing request/response/error interceptors should expose a
/// settings object that implements this interface so shared network log
/// builders can produce consistent output.
abstract interface class NetworkLogPrintOptions {
  /// Whether request bodies should be printed in the log message.
  bool get printRequestData;

  /// Whether request headers should be printed in the log message.
  bool get printRequestHeaders;

  /// Whether response payloads should be printed in the log message.
  bool get printResponseData;

  /// Whether response headers should be printed in the log message.
  bool get printResponseHeaders;

  /// Whether the response status message should be printed.
  bool get printResponseMessage;

  /// Whether error payloads should be printed in the log message.
  bool get printErrorData;

  /// Whether error headers should be printed in the log message.
  bool get printErrorHeaders;

  /// Whether the error status/message should be printed in the log summary.
  bool get printErrorMessage;

  /// Optional pen to override the default request log color.
  AnsiPen? get requestPen;

  /// Optional pen to override the default response log color.
  AnsiPen? get responsePen;

  /// Optional pen to override the default error log color.
  AnsiPen? get errorPen;
}
