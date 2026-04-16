import 'package:ispectify/ispectify.dart';

// ignore_for_file: avoid_returning_this

/// Base builder for network interceptor settings.
///
/// Provides all common builder methods (redaction toggles, data/header
/// visibility, pens, environment presets, filters) via a self-referential
/// generic so that subclass methods return the correct builder type for
/// fluent chaining.
///
/// Type parameters:
/// - [B] — the concrete builder type (self-referential for fluent chaining)
/// - [TReq] — the type passed to the request filter function
/// - [TRes] — the type passed to the response filter function
/// - [TErr] — the type passed to the error filter function
///
/// Subclasses must:
/// 1. Extend `BaseNetworkInterceptorSettingsBuilder<ConcreteBuilder, ...>`
/// 2. Override [build] to construct the package-specific settings object
abstract class BaseNetworkInterceptorSettingsBuilder<
    B extends BaseNetworkInterceptorSettingsBuilder<B, TReq, TRes, TErr>,
    TReq,
    TRes,
    TErr> {
  /// Creates a builder with default settings (moderate verbosity).
  BaseNetworkInterceptorSettingsBuilder()
      : enabled = true,
        enableRedaction = true,
        printResponseData = true,
        printResponseHeaders = false,
        printResponseMessage = true,
        printErrorData = true,
        printErrorHeaders = true,
        printErrorMessage = true,
        printRequestData = true,
        printRequestHeaders = false;

  bool enabled;
  bool enableRedaction;
  bool printResponseData;
  bool printResponseHeaders;
  bool printResponseMessage;
  bool printErrorData;
  bool printErrorHeaders;
  bool printErrorMessage;
  bool printRequestData;
  bool printRequestHeaders;
  AnsiPen? requestPen;
  AnsiPen? responsePen;
  AnsiPen? errorPen;

  bool Function(TReq)? requestFilter;
  bool Function(TRes)? responseFilter;
  bool Function(TErr)? errorFilter;

  /// Returns `this` cast to the concrete builder type for fluent chaining.
  B get _self => this as B;

  // ---------------------------------------------------------------------------
  // Enable / disable
  // ---------------------------------------------------------------------------

  /// Enables the interceptor (enabled by default).
  B withEnabled() {
    enabled = true;
    return _self;
  }

  /// Disables the interceptor.
  B withDisabled() {
    enabled = false;
    return _self;
  }

  // ---------------------------------------------------------------------------
  // Redaction
  // ---------------------------------------------------------------------------

  /// Enables sensitive data redaction.
  B withRedaction() {
    enableRedaction = true;
    return _self;
  }

  /// Disables sensitive data redaction (use only in dev/test environments).
  B withoutRedaction() {
    enableRedaction = false;
    return _self;
  }

  // ---------------------------------------------------------------------------
  // Individual toggles
  // ---------------------------------------------------------------------------

  /// Enables printing of response data.
  B withResponseData() {
    printResponseData = true;
    return _self;
  }

  /// Enables printing of response headers.
  B withResponseHeaders() {
    printResponseHeaders = true;
    return _self;
  }

  /// Enables printing of response status messages.
  B withResponseMessage() {
    printResponseMessage = true;
    return _self;
  }

  /// Enables printing of error data.
  B withErrorData() {
    printErrorData = true;
    return _self;
  }

  /// Enables printing of error headers.
  B withErrorHeaders() {
    printErrorHeaders = true;
    return _self;
  }

  /// Enables printing of error messages.
  B withErrorMessage() {
    printErrorMessage = true;
    return _self;
  }

  /// Enables printing of request data.
  B withRequestData() {
    printRequestData = true;
    return _self;
  }

  /// Enables printing of request headers.
  B withRequestHeaders() {
    printRequestHeaders = true;
    return _self;
  }

  // ---------------------------------------------------------------------------
  // Bulk toggles
  // ---------------------------------------------------------------------------

  /// Enables printing of all headers (request, response, error).
  B withAllHeaders() {
    printRequestHeaders = true;
    printResponseHeaders = true;
    printErrorHeaders = true;
    return _self;
  }

  /// Enables printing of all data (request, response, error).
  B withAllData() {
    printRequestData = true;
    printResponseData = true;
    printErrorData = true;
    return _self;
  }

  /// Configures to log only errors (disables request/response logging).
  B withErrorsOnly() {
    printRequestData = false;
    printRequestHeaders = false;
    printResponseData = false;
    printResponseHeaders = false;
    printResponseMessage = false;
    printErrorData = true;
    printErrorHeaders = true;
    printErrorMessage = true;
    return _self;
  }

  // ---------------------------------------------------------------------------
  // Pens
  // ---------------------------------------------------------------------------

  /// Sets custom color for request logs.
  B withRequestPen(AnsiPen pen) {
    requestPen = pen;
    return _self;
  }

  /// Sets custom color for response logs.
  B withResponsePen(AnsiPen pen) {
    responsePen = pen;
    return _self;
  }

  /// Sets custom color for error logs.
  B withErrorPen(AnsiPen pen) {
    errorPen = pen;
    return _self;
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  /// Sets a custom request filter.
  ///
  /// Only requests where the filter returns `true` will be logged.
  B withRequestFilter(bool Function(TReq) filter) {
    requestFilter = filter;
    return _self;
  }

  /// Sets a custom response filter.
  ///
  /// Only responses where the filter returns `true` will be logged.
  B withResponseFilter(bool Function(TRes) filter) {
    responseFilter = filter;
    return _self;
  }

  /// Sets a custom error filter.
  ///
  /// Only errors where the filter returns `true` will be logged.
  B withErrorFilter(bool Function(TErr) filter) {
    errorFilter = filter;
    return _self;
  }

  // ---------------------------------------------------------------------------
  // Environment presets
  // ---------------------------------------------------------------------------

  /// Applies development preset: all headers, all data, redaction enabled.
  void applyDevelopmentDefaults() {
    withAllHeaders();
    withRedaction();
    withAllData();
  }

  /// Applies production preset: errors only, redaction enabled.
  void applyProductionDefaults() {
    withRedaction();
    withErrorsOnly();
  }

  /// Applies staging preset: request data + errors, redaction enabled.
  void applyStagingDefaults() {
    withRedaction();
    withRequestData();
    withErrorData();
  }

  /// Builds the concrete settings object. Subclasses must override to
  /// construct the package-specific settings type.
  BaseNetworkInterceptorSettings build();
}
