import 'package:ispectify/ispectify.dart';

/// Base settings class for network interceptors (Dio, HTTP, etc.).
///
/// Contains all common configuration fields shared across network interceptor
/// implementations. Package-specific settings (e.g. filter callbacks) should be
/// added in subclasses.
///
/// Supports `const` construction for compile-time constant defaults.
abstract class BaseNetworkInterceptorSettings
    implements NetworkLogPrintOptions {
  const BaseNetworkInterceptorSettings({
    this.enabled = true,
    this.enableRedaction = true,
    this.printResponseData = true,
    this.printResponseHeaders = false,
    this.printResponseMessage = true,
    this.printErrorData = true,
    this.printErrorHeaders = true,
    this.printErrorMessage = true,
    this.printRequestData = true,
    this.printRequestHeaders = false,
    this.requestPen,
    this.responsePen,
    this.errorPen,
  });

  /// Enable HTTP request/response logging when `true`.
  final bool enabled;

  /// Enable sensitive data redaction when `true` (default: `true`).
  final bool enableRedaction;

  /// Print response body in the log message.
  @override
  final bool printResponseData;

  /// Print response headers in the log message.
  @override
  final bool printResponseHeaders;

  /// Print response status message in the log message.
  @override
  final bool printResponseMessage;

  /// Print error body in the log message.
  @override
  final bool printErrorData;

  /// Print error headers in the log message.
  @override
  final bool printErrorHeaders;

  /// Print error status message in the log message.
  @override
  final bool printErrorMessage;

  /// Print request body in the log message.
  @override
  final bool printRequestData;

  /// Print request headers in the log message.
  @override
  final bool printRequestHeaders;

  /// Custom [AnsiPen] for request log console output.
  @override
  final AnsiPen? requestPen;

  /// Custom [AnsiPen] for response log console output.
  @override
  final AnsiPen? responsePen;

  /// Custom [AnsiPen] for error log console output.
  @override
  final AnsiPen? errorPen;

  /// Creates a copy with the given fields replaced.
  ///
  /// Subclasses must override to preserve their own fields (e.g. filter
  /// callbacks) while delegating the base-field handling to this declaration.
  BaseNetworkInterceptorSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
  });
}
