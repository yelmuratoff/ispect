import 'package:ispectify/ispectify.dart';

/// Shared defaults for every ISpect network diagnostics adapter.
///
/// Adapter settings and fluent builders both read from this namespace so the
/// default capture contract cannot drift between construction paths.
abstract final class NetworkInterceptorDefaults {
  /// Interceptors capture diagnostics by default.
  static const enabled = true;

  /// Sensitive values are masked by default.
  static const enableRedaction = true;

  /// Useful bounded application values are captured by default.
  static const captureMode = DiagnosticCaptureMode.balanced;

  /// Adapters inherit resource budgets from their logger by default.
  static const DiagnosticResourceLimits? resourceLimits = null;

  /// Routine request diagnostics are retained by default.
  static const logRequests = true;

  /// Routine response diagnostics are retained by default.
  static const logResponses = true;

  /// Response bodies are included by default.
  static const printResponseData = true;

  /// Response headers are included by default.
  static const printResponseHeaders = true;

  /// Response status messages are included by default.
  static const printResponseMessage = true;

  /// Error bodies are included by default.
  static const printErrorData = true;

  /// Error headers are included by default.
  static const printErrorHeaders = true;

  /// Error messages are included by default.
  static const printErrorMessage = true;

  /// Request bodies are included by default.
  static const printRequestData = true;

  /// Request headers are included by default.
  static const printRequestHeaders = true;
}

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
    this.enabled = NetworkInterceptorDefaults.enabled,
    this.enableRedaction = NetworkInterceptorDefaults.enableRedaction,
    this.captureMode = NetworkInterceptorDefaults.captureMode,
    this.resourceLimits = NetworkInterceptorDefaults.resourceLimits,
    this.logRequests = NetworkInterceptorDefaults.logRequests,
    this.logResponses = NetworkInterceptorDefaults.logResponses,
    this.printResponseData = NetworkInterceptorDefaults.printResponseData,
    this.printResponseHeaders = NetworkInterceptorDefaults.printResponseHeaders,
    this.printResponseMessage = NetworkInterceptorDefaults.printResponseMessage,
    this.printErrorData = NetworkInterceptorDefaults.printErrorData,
    this.printErrorHeaders = NetworkInterceptorDefaults.printErrorHeaders,
    this.printErrorMessage = NetworkInterceptorDefaults.printErrorMessage,
    this.printRequestData = NetworkInterceptorDefaults.printRequestData,
    this.printRequestHeaders = NetworkInterceptorDefaults.printRequestHeaders,
    this.requestPen,
    this.responsePen,
    this.errorPen,
  });

  /// Enable HTTP request/response logging when `true`.
  final bool enabled;

  /// Enable sensitive data redaction when `true` (default: `true`).
  final bool enableRedaction;

  /// Whether this adapter masks values: its own [enableRedaction] flag
  /// combined with the process-wide [ISpectRedaction.enabled] switch.
  bool get isRedactionActive => enableRedaction && ISpectRedaction.enabled;

  /// Controls whether application-defined payload formatters may run.
  final DiagnosticCaptureMode captureMode;

  /// Optional adapter-specific budgets. `null` inherits the logger policy.
  final DiagnosticResourceLimits? resourceLimits;

  /// Retain normal request diagnostics.
  final bool logRequests;

  /// Retain normal response diagnostics.
  final bool logResponses;

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
  /// [inheritResourceLimits] clears an adapter override and takes precedence
  /// over [resourceLimits].
  BaseNetworkInterceptorSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    DiagnosticCaptureMode? captureMode,
    DiagnosticResourceLimits? resourceLimits,
    bool inheritResourceLimits = false,
    bool? logRequests,
    bool? logResponses,
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
