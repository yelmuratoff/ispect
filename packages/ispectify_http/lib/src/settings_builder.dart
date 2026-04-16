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
        ISpectHttpInterceptorSettingsBuilder,
        BaseRequest,
        BaseResponse,
        BaseResponse> {
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
        requestFilter: requestFilter,
        responseFilter: responseFilter,
        errorFilter: errorFilter,
      );
}
