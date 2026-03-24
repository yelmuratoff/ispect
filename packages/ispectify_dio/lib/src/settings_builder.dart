// ignore_for_file: avoid_returning_this
import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/settings.dart';

/// Builder for [ISpectDioInterceptorSettings] providing fluent API.
///
/// {@tool snippet}
/// ```dart
/// final settings = ISpectDioInterceptorSettingsBuilder()
///   .withRequestHeaders()
///   .withResponseHeaders()
///   .withRedaction()
///   .build();
/// ```
/// {@end-tool}
class ISpectDioInterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<
        ISpectDioInterceptorSettingsBuilder> {
  /// Creates a builder with default settings (moderate verbosity).
  ISpectDioInterceptorSettingsBuilder();

  /// Development: verbose logging, redaction enabled.
  factory ISpectDioInterceptorSettingsBuilder.development() =>
      ISpectDioInterceptorSettingsBuilder()..applyDevelopmentDefaults();

  /// Production: errors only, redaction enabled.
  factory ISpectDioInterceptorSettingsBuilder.production() =>
      ISpectDioInterceptorSettingsBuilder()..applyProductionDefaults();

  /// Staging: requests + errors, redaction enabled.
  factory ISpectDioInterceptorSettingsBuilder.staging() =>
      ISpectDioInterceptorSettingsBuilder()..applyStagingDefaults();

  /// Logging disabled.
  factory ISpectDioInterceptorSettingsBuilder.disabled() =>
      ISpectDioInterceptorSettingsBuilder()..enabled = false;

  bool Function(RequestOptions requestOptions)? _requestFilter;
  bool Function(Response<dynamic> response)? _responseFilter;
  bool Function(DioException response)? _errorFilter;

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

  @override
  ISpectDioInterceptorSettings build() => ISpectDioInterceptorSettings(
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
