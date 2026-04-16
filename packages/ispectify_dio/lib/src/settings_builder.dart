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
        ISpectDioInterceptorSettingsBuilder,
        RequestOptions,
        Response<dynamic>,
        DioException> {
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
        requestFilter: requestFilter,
        responseFilter: responseFilter,
        errorFilter: errorFilter,
      );
}
