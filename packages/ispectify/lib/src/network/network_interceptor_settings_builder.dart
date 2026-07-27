import 'package:ispectify/ispectify.dart';

// ignore_for_file: avoid_returning_this, deprecated_member_use_from_same_package

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
  /// Creates a builder with metadata-only defaults.
  BaseNetworkInterceptorSettingsBuilder()
      : enabled = true,
        enableRedaction = true,
        logRequests = true,
        logResponses = true,
        printResponseData = false,
        printResponseHeaders = false,
        printResponseMessage = true,
        printErrorData = false,
        printErrorHeaders = false,
        printErrorMessage = true,
        printRequestData = false,
        printRequestHeaders = false;

  bool enabled;
  bool enableRedaction;
  bool logRequests;
  bool logResponses;
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

  @Deprecated('Use requestChain instead. Will be removed in 8.0.0.')
  bool Function(TReq)? requestFilter;
  @Deprecated('Use responseChain instead. Will be removed in 8.0.0.')
  bool Function(TRes)? responseFilter;
  @Deprecated('Use errorChain instead. Will be removed in 8.0.0.')
  bool Function(TErr)? errorFilter;

  NetworkFilterChain<TReq>? requestChain;
  NetworkFilterChain<TRes>? responseChain;
  NetworkFilterChain<TErr>? errorChain;

  /// Returns `this` cast to the concrete builder type for fluent chaining.
  B get _self => this as B;

  // Enable / disable

  /// Enables the interceptor (enabled by default).
  B withEnabled() {
    enabled = true;
    return _self;
  }

  /// Enables normal request diagnostics.
  B withRequests() {
    logRequests = true;
    return _self;
  }

  /// Disables normal request diagnostics.
  B withoutRequests() {
    logRequests = false;
    return _self;
  }

  /// Enables normal response diagnostics.
  B withResponses() {
    logResponses = true;
    return _self;
  }

  /// Disables normal response diagnostics.
  B withoutResponses() {
    logResponses = false;
    return _self;
  }

  /// Disables the interceptor.
  B withDisabled() {
    enabled = false;
    return _self;
  }

  // Redaction

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

  // Individual toggles

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

  // Bulk toggles

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
    logRequests = false;
    logResponses = false;
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

  // Pens

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

  // Filters (legacy — prefer filter chains)

  /// Sets a custom request filter callback.
  @Deprecated('Use withRequestChain instead. Will be removed in 8.0.0.')
  B withRequestFilter(bool Function(TReq) filter) {
    requestFilter = filter;
    return _self;
  }

  /// Sets a custom response filter callback.
  @Deprecated('Use withResponseChain instead. Will be removed in 8.0.0.')
  B withResponseFilter(bool Function(TRes) filter) {
    responseFilter = filter;
    return _self;
  }

  /// Sets a custom error filter callback.
  @Deprecated('Use withErrorChain instead. Will be removed in 8.0.0.')
  B withErrorFilter(bool Function(TErr) filter) {
    errorFilter = filter;
    return _self;
  }

  // Filter chains

  /// Sets a [NetworkFilterChain] for request filtering.
  B withRequestChain(NetworkFilterChain<TReq> chain) {
    requestChain = chain;
    return _self;
  }

  /// Sets a [NetworkFilterChain] for response filtering.
  B withResponseChain(NetworkFilterChain<TRes> chain) {
    responseChain = chain;
    return _self;
  }

  /// Sets a [NetworkFilterChain] for error filtering.
  B withErrorChain(NetworkFilterChain<TErr> chain) {
    errorChain = chain;
    return _self;
  }

  // Environment presets

  /// Applies development preset: all headers, all data, redaction enabled.
  void applyDevelopmentDefaults() {
    logRequests = true;
    logResponses = true;
    withAllHeaders();
    withRedaction();
    withAllData();
  }

  /// Applies production preset: errors only, redaction enabled.
  void applyProductionDefaults() {
    withRedaction();
    withErrorsOnly();
    printErrorData = false;
    printErrorHeaders = false;
  }

  /// Applies staging preset: request data + errors, redaction enabled.
  void applyStagingDefaults() {
    logRequests = true;
    logResponses = false;
    withRedaction();
    withRequestData();
    withErrorData();
  }

  /// Builds the concrete settings object. Subclasses must override to
  /// construct the package-specific settings type.
  BaseNetworkInterceptorSettings build();
}
