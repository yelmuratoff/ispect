import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/settings.dart';

// ignore_for_file: avoid_returning_this

/// Builder for [ISpectDioInterceptorSettings] providing fluent API for configuration.
///
/// Simplifies settings creation with sensible defaults and method chaining.
///
/// {@tool snippet}
/// Basic usage:
/// ```dart
/// final settings = ISpectDioInterceptorSettingsBuilder()
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
/// final devSettings = ISpectDioInterceptorSettingsBuilder.development()
///   .build();
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Production environment (minimal logging, full redaction):
/// ```dart
/// final prodSettings = ISpectDioInterceptorSettingsBuilder.production()
///   .build();
/// ```
/// {@end-tool}
class ISpectDioInterceptorSettingsBuilder {
  /// Creates a builder with default settings (moderate verbosity).
  ISpectDioInterceptorSettingsBuilder()
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
  factory ISpectDioInterceptorSettingsBuilder.development() =>
      ISpectDioInterceptorSettingsBuilder()
        ..withAllHeaders()
        ..withoutRedaction()
        ..withAllData();

  /// Creates a builder configured for production (minimal, with redaction).
  ///
  /// Logs only errors with sensitive data redacted.
  factory ISpectDioInterceptorSettingsBuilder.production() =>
      ISpectDioInterceptorSettingsBuilder()
        ..withRedaction()
        ..withErrorsOnly();

  /// Creates a builder configured for staging (balanced logging).
  ///
  /// Logs requests and errors with redaction enabled.
  factory ISpectDioInterceptorSettingsBuilder.staging() =>
      ISpectDioInterceptorSettingsBuilder()
        ..withRedaction()
        ..withRequestData()
        ..withErrorData();

  /// Creates a builder with logging disabled.
  ///
  /// Useful for temporarily disabling the interceptor without removing it.
  factory ISpectDioInterceptorSettingsBuilder.disabled() =>
      ISpectDioInterceptorSettingsBuilder().._enabled = false;

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
  bool Function(RequestOptions requestOptions)? _requestFilter;
  bool Function(Response<dynamic> response)? _responseFilter;
  bool Function(DioException response)? _errorFilter;

  /// Enables the interceptor (enabled by default).
  ISpectDioInterceptorSettingsBuilder withEnabled() {
    _enabled = true;
    return this;
  }

  /// Disables the interceptor.
  ISpectDioInterceptorSettingsBuilder withDisabled() {
    _enabled = false;
    return this;
  }

  /// Enables sensitive data redaction.
  ISpectDioInterceptorSettingsBuilder withRedaction() {
    _enableRedaction = true;
    return this;
  }

  /// Disables sensitive data redaction (use only in dev/test environments).
  ISpectDioInterceptorSettingsBuilder withoutRedaction() {
    _enableRedaction = false;
    return this;
  }

  /// Enables printing of response data.
  ISpectDioInterceptorSettingsBuilder withResponseData() {
    _printResponseData = true;
    return this;
  }

  /// Enables printing of response headers.
  ISpectDioInterceptorSettingsBuilder withResponseHeaders() {
    _printResponseHeaders = true;
    return this;
  }

  /// Enables printing of response status messages.
  ISpectDioInterceptorSettingsBuilder withResponseMessage() {
    _printResponseMessage = true;
    return this;
  }

  /// Enables printing of error data.
  ISpectDioInterceptorSettingsBuilder withErrorData() {
    _printErrorData = true;
    return this;
  }

  /// Enables printing of error headers.
  ISpectDioInterceptorSettingsBuilder withErrorHeaders() {
    _printErrorHeaders = true;
    return this;
  }

  /// Enables printing of error messages.
  ISpectDioInterceptorSettingsBuilder withErrorMessage() {
    _printErrorMessage = true;
    return this;
  }

  /// Enables printing of request data.
  ISpectDioInterceptorSettingsBuilder withRequestData() {
    _printRequestData = true;
    return this;
  }

  /// Enables printing of request headers.
  ISpectDioInterceptorSettingsBuilder withRequestHeaders() {
    _printRequestHeaders = true;
    return this;
  }

  /// Enables printing of all headers (request, response, error).
  ISpectDioInterceptorSettingsBuilder withAllHeaders() {
    _printRequestHeaders = true;
    _printResponseHeaders = true;
    _printErrorHeaders = true;
    return this;
  }

  /// Enables printing of all data (request, response, error).
  ISpectDioInterceptorSettingsBuilder withAllData() {
    _printRequestData = true;
    _printResponseData = true;
    _printErrorData = true;
    return this;
  }

  /// Configures to log only errors (disables request/response logging).
  ISpectDioInterceptorSettingsBuilder withErrorsOnly() {
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
  ISpectDioInterceptorSettingsBuilder withRequestPen(AnsiPen pen) {
    _requestPen = pen;
    return this;
  }

  /// Sets custom color for response logs.
  ISpectDioInterceptorSettingsBuilder withResponsePen(AnsiPen pen) {
    _responsePen = pen;
    return this;
  }

  /// Sets custom color for error logs.
  ISpectDioInterceptorSettingsBuilder withErrorPen(AnsiPen pen) {
    _errorPen = pen;
    return this;
  }

  /// Sets a custom request filter.
  ///
  /// Only requests where the filter returns `true` will be logged.
  ISpectDioInterceptorSettingsBuilder withRequestFilter(
    bool Function(RequestOptions) filter,
  ) {
    _requestFilter = filter;
    return this;
  }

  /// Sets a custom response filter.
  ///
  /// Only responses where the filter returns `true` will be logged.
  ISpectDioInterceptorSettingsBuilder withResponseFilter(
    bool Function(Response<dynamic>) filter,
  ) {
    _responseFilter = filter;
    return this;
  }

  /// Sets a custom error filter.
  ///
  /// Only errors where the filter returns `true` will be logged.
  ISpectDioInterceptorSettingsBuilder withErrorFilter(
    bool Function(DioException) filter,
  ) {
    _errorFilter = filter;
    return this;
  }

  /// Builds the [ISpectDioInterceptorSettings] instance.
  ISpectDioInterceptorSettings build() => ISpectDioInterceptorSettings(
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
