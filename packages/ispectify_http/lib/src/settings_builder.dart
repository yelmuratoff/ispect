import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/settings.dart';

// ignore_for_file: avoid_returning_this

/// Builder for [ISpectHttpInterceptorSettings] providing fluent API for configuration.
///
/// Simplifies settings creation with sensible defaults and method chaining.
///
/// {@tool snippet}
/// Basic usage:
/// ```dart
/// final settings = ISpectHttpInterceptorSettingsBuilder()
///   .withRequestHeaders()
///   .withResponseHeaders()
///   .withRedaction()
///   .build();
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Development environment (verbose logging, no redaction):
/// ```dart
/// final devSettings = ISpectHttpInterceptorSettingsBuilder.development()
///   .build();
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Production environment (minimal logging, full redaction):
/// ```dart
/// final prodSettings = ISpectHttpInterceptorSettingsBuilder.production()
///   .build();
/// ```
/// {@end-tool}
class ISpectHttpInterceptorSettingsBuilder {
  /// Creates a builder with default settings (moderate verbosity).
  ISpectHttpInterceptorSettingsBuilder()
      : _enabled = true,
        _enableRedaction = false,
        _printResponseData = true,
        _printResponseHeaders = false,
        _printResponseMessage = true,
        _printErrorData = true,
        _printErrorHeaders = true,
        _printErrorMessage = true,
        _printRequestData = true,
        _printRequestHeaders = false;

  /// Creates a builder configured for development (verbose, no redaction).
  ///
  /// Ideal for local debugging with full visibility into all requests/responses.
  factory ISpectHttpInterceptorSettingsBuilder.development() =>
      ISpectHttpInterceptorSettingsBuilder()
        ..withAllHeaders()
        ..withoutRedaction()
        ..withAllData();

  /// Creates a builder configured for production (minimal, with redaction).
  ///
  /// Logs only errors with sensitive data redacted.
  factory ISpectHttpInterceptorSettingsBuilder.production() =>
      ISpectHttpInterceptorSettingsBuilder()
        ..withRedaction()
        ..withErrorsOnly();

  /// Creates a builder configured for staging (balanced logging).
  ///
  /// Logs requests and errors with redaction enabled.
  factory ISpectHttpInterceptorSettingsBuilder.staging() =>
      ISpectHttpInterceptorSettingsBuilder()
        ..withRedaction()
        ..withRequestData()
        ..withErrorData();

  /// Creates a builder with logging disabled.
  ///
  /// Useful for temporarily disabling the interceptor without removing it.
  factory ISpectHttpInterceptorSettingsBuilder.disabled() =>
      ISpectHttpInterceptorSettingsBuilder().._enabled = false;

  bool _enabled;
  bool _enableRedaction;
  bool _printResponseData;
  bool _printResponseHeaders;
  bool _printResponseMessage;
  bool _printErrorData;
  bool _printErrorHeaders;
  bool _printErrorMessage;
  bool _printRequestData;
  bool _printRequestHeaders;
  AnsiPen? _requestPen;
  AnsiPen? _responsePen;
  AnsiPen? _errorPen;
  bool Function(BaseRequest request)? _requestFilter;
  bool Function(BaseResponse response)? _responseFilter;
  bool Function(BaseResponse response)? _errorFilter;

  /// Enables the interceptor (enabled by default).
  ISpectHttpInterceptorSettingsBuilder withEnabled() {
    _enabled = true;
    return this;
  }

  /// Disables the interceptor.
  ISpectHttpInterceptorSettingsBuilder withDisabled() {
    _enabled = false;
    return this;
  }

  /// Enables sensitive data redaction.
  ISpectHttpInterceptorSettingsBuilder withRedaction() {
    _enableRedaction = true;
    return this;
  }

  /// Disables sensitive data redaction (use only in dev/test environments).
  ISpectHttpInterceptorSettingsBuilder withoutRedaction() {
    _enableRedaction = false;
    return this;
  }

  /// Enables printing of response data.
  ISpectHttpInterceptorSettingsBuilder withResponseData() {
    _printResponseData = true;
    return this;
  }

  /// Enables printing of response headers.
  ISpectHttpInterceptorSettingsBuilder withResponseHeaders() {
    _printResponseHeaders = true;
    return this;
  }

  /// Enables printing of response status messages.
  ISpectHttpInterceptorSettingsBuilder withResponseMessage() {
    _printResponseMessage = true;
    return this;
  }

  /// Enables printing of error data.
  ISpectHttpInterceptorSettingsBuilder withErrorData() {
    _printErrorData = true;
    return this;
  }

  /// Enables printing of error headers.
  ISpectHttpInterceptorSettingsBuilder withErrorHeaders() {
    _printErrorHeaders = true;
    return this;
  }

  /// Enables printing of error messages.
  ISpectHttpInterceptorSettingsBuilder withErrorMessage() {
    _printErrorMessage = true;
    return this;
  }

  /// Enables printing of request data.
  ISpectHttpInterceptorSettingsBuilder withRequestData() {
    _printRequestData = true;
    return this;
  }

  /// Enables printing of request headers.
  ISpectHttpInterceptorSettingsBuilder withRequestHeaders() {
    _printRequestHeaders = true;
    return this;
  }

  /// Enables printing of all headers (request, response, error).
  ISpectHttpInterceptorSettingsBuilder withAllHeaders() {
    _printRequestHeaders = true;
    _printResponseHeaders = true;
    _printErrorHeaders = true;
    return this;
  }

  /// Enables printing of all data (request, response, error).
  ISpectHttpInterceptorSettingsBuilder withAllData() {
    _printRequestData = true;
    _printResponseData = true;
    _printErrorData = true;
    return this;
  }

  /// Configures to log only errors (disables request/response logging).
  ISpectHttpInterceptorSettingsBuilder withErrorsOnly() {
    _printRequestData = false;
    _printRequestHeaders = false;
    _printResponseData = false;
    _printResponseHeaders = false;
    _printResponseMessage = false;
    _printErrorData = true;
    _printErrorHeaders = true;
    _printErrorMessage = true;
    return this;
  }

  /// Sets custom color for request logs.
  ISpectHttpInterceptorSettingsBuilder withRequestPen(AnsiPen pen) {
    _requestPen = pen;
    return this;
  }

  /// Sets custom color for response logs.
  ISpectHttpInterceptorSettingsBuilder withResponsePen(AnsiPen pen) {
    _responsePen = pen;
    return this;
  }

  /// Sets custom color for error logs.
  ISpectHttpInterceptorSettingsBuilder withErrorPen(AnsiPen pen) {
    _errorPen = pen;
    return this;
  }

  /// Sets a custom request filter.
  ///
  /// Only requests where the filter returns `true` will be logged.
  ISpectHttpInterceptorSettingsBuilder withRequestFilter(
    bool Function(BaseRequest) filter,
  ) {
    _requestFilter = filter;
    return this;
  }

  /// Sets a custom response filter.
  ///
  /// Only responses where the filter returns `true` will be logged.
  ISpectHttpInterceptorSettingsBuilder withResponseFilter(
    bool Function(BaseResponse) filter,
  ) {
    _responseFilter = filter;
    return this;
  }

  /// Sets a custom error filter.
  ///
  /// Only errors where the filter returns `true` will be logged.
  ISpectHttpInterceptorSettingsBuilder withErrorFilter(
    bool Function(BaseResponse) filter,
  ) {
    _errorFilter = filter;
    return this;
  }

  /// Builds the [ISpectHttpInterceptorSettings] instance.
  ISpectHttpInterceptorSettings build() => ISpectHttpInterceptorSettings(
        enabled: _enabled,
        enableRedaction: _enableRedaction,
        printResponseData: _printResponseData,
        printResponseHeaders: _printResponseHeaders,
        printResponseMessage: _printResponseMessage,
        printErrorData: _printErrorData,
        printErrorHeaders: _printErrorHeaders,
        printErrorMessage: _printErrorMessage,
        printRequestData: _printRequestData,
        printRequestHeaders: _printRequestHeaders,
        requestPen: _requestPen,
        responsePen: _responsePen,
        errorPen: _errorPen,
        requestFilter: _requestFilter,
        responseFilter: _responseFilter,
        errorFilter: _errorFilter,
      );
}
