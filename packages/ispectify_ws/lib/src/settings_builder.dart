// ignore_for_file: avoid_returning_this
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

/// Builder for [ISpectWSInterceptorSettings] providing fluent API.
///
/// Provides WS-specific aliases: [withSentFilter] / [withReceivedFilter]
/// map to the base [withRequestFilter] / [withResponseFilter] methods.
class ISpectWSInterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<
        ISpectWSInterceptorSettingsBuilder,
        ISpectLogData,
        ISpectLogData,
        ISpectLogData> {
  ISpectWSInterceptorSettingsBuilder();

  factory ISpectWSInterceptorSettingsBuilder.development() =>
      ISpectWSInterceptorSettingsBuilder()..applyDevelopmentDefaults();

  factory ISpectWSInterceptorSettingsBuilder.production() =>
      ISpectWSInterceptorSettingsBuilder()..applyProductionDefaults();

  factory ISpectWSInterceptorSettingsBuilder.staging() =>
      ISpectWSInterceptorSettingsBuilder()..applyStagingDefaults();

  factory ISpectWSInterceptorSettingsBuilder.disabled() =>
      ISpectWSInterceptorSettingsBuilder()..enabled = false;

  /// Alias for [withRequestFilter] using WS naming convention.
  ISpectWSInterceptorSettingsBuilder withSentFilter(
    bool Function(ISpectLogData data) filter,
  ) =>
      withRequestFilter(filter);

  /// Alias for [withResponseFilter] using WS naming convention.
  ISpectWSInterceptorSettingsBuilder withReceivedFilter(
    bool Function(ISpectLogData data) filter,
  ) =>
      withResponseFilter(filter);

  @override
  ISpectWSInterceptorSettings build() => ISpectWSInterceptorSettings(
        enabled: enabled,
        enableRedaction: enableRedaction,
        printReceivedData: printResponseData,
        printReceivedHeaders: printResponseHeaders,
        printReceivedMessage: printResponseMessage,
        printErrorData: printErrorData,
        printErrorMessage: printErrorMessage,
        printSentData: printRequestData,
        printSentHeaders: printRequestHeaders,
        sentPen: requestPen,
        receivedPen: responsePen,
        errorPen: errorPen,
        sentFilter: requestFilter,
        receivedFilter: responseFilter,
        errorFilter: errorFilter,
      );
}
