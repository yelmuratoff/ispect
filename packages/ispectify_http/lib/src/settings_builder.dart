// ignore_for_file: avoid_returning_this
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/settings.dart';

/// Builder for [ISpectHttpInterceptorSettings] providing fluent API.
///
/// {@tool snippet}
/// ```dart
/// final settings = ISpectHttpInterceptorSettingsBuilder()
///   .withRequestHeaders()
///   .withResponseHeaders()
///   .withRedaction()
///   .build();
/// ```
/// {@end-tool}
class ISpectHttpInterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<
        ISpectHttpInterceptorSettingsBuilder> {
  /// Creates a builder with default settings (moderate verbosity).
  ISpectHttpInterceptorSettingsBuilder();

  /// Development: verbose logging, redaction enabled.
  factory ISpectHttpInterceptorSettingsBuilder.development() =>
      ISpectHttpInterceptorSettingsBuilder()..applyDevelopmentDefaults();

  /// Production: errors only, redaction enabled.
  factory ISpectHttpInterceptorSettingsBuilder.production() =>
      ISpectHttpInterceptorSettingsBuilder()..applyProductionDefaults();

  /// Staging: requests + errors, redaction enabled.
  factory ISpectHttpInterceptorSettingsBuilder.staging() =>
      ISpectHttpInterceptorSettingsBuilder()..applyStagingDefaults();

  /// Logging disabled.
  factory ISpectHttpInterceptorSettingsBuilder.disabled() =>
      ISpectHttpInterceptorSettingsBuilder()..enabled = false;

  bool Function(BaseRequest request)? _requestFilter;
  bool Function(BaseResponse response)? _responseFilter;
  bool Function(BaseResponse response)? _errorFilter;

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

  @override
  ISpectHttpInterceptorSettings build() => ISpectHttpInterceptorSettings(
        enabled: enabled,
        enableRedaction: enableRedaction,
        printResponseData: printResponseData,
        printResponseHeaders: printResponseHeaders,
        printResponseMessage: printResponseMessage,
        printErrorData: printErrorData,
        printErrorHeaders: printErrorHeaders,
        printErrorMessage: printErrorMessage,
        printRequestData: printRequestData,
        printRequestHeaders: printRequestHeaders,
        requestPen: requestPen,
        responsePen: responsePen,
        errorPen: errorPen,
        requestFilter: _requestFilter,
        responseFilter: _responseFilter,
        errorFilter: _errorFilter,
      );
}
