// ignore_for_file: avoid_returning_this, deprecated_member_use, deprecated_member_use_from_same_package
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
      ISpectWSInterceptorSettingsBuilder()
        ..applyDevelopmentDefaults()
        ..printRequestHeaders = false
        ..printResponseHeaders = false
        ..printErrorHeaders = false
        ..printStateData = true;

  factory ISpectWSInterceptorSettingsBuilder.production() =>
      ISpectWSInterceptorSettingsBuilder()..applyProductionDefaults();

  factory ISpectWSInterceptorSettingsBuilder.staging() =>
      ISpectWSInterceptorSettingsBuilder()..applyStagingDefaults();

  factory ISpectWSInterceptorSettingsBuilder.disabled() =>
      ISpectWSInterceptorSettingsBuilder()..enabled = false;

  bool printStateData = false;

  /// Retains raw adapter connection-state details.
  ISpectWSInterceptorSettingsBuilder withStateData() {
    printStateData = true;
    return this;
  }

  /// Omits raw adapter connection-state details.
  ISpectWSInterceptorSettingsBuilder withoutStateData() {
    printStateData = false;
    return this;
  }

  /// Alias for [withRequestFilter] using WS naming convention.
  @Deprecated('Use withSentChain instead. Will be removed in 8.0.0.')
  ISpectWSInterceptorSettingsBuilder withSentFilter(
    bool Function(ISpectLogData data) filter,
  ) =>
      withRequestFilter(filter);

  /// Alias for [withResponseFilter] using WS naming convention.
  @Deprecated('Use withReceivedChain instead. Will be removed in 8.0.0.')
  ISpectWSInterceptorSettingsBuilder withReceivedFilter(
    bool Function(ISpectLogData data) filter,
  ) =>
      withResponseFilter(filter);

  /// Sets a [NetworkFilterChain] for sent message filtering (WS alias).
  ISpectWSInterceptorSettingsBuilder withSentChain(
    NetworkFilterChain<ISpectLogData> chain,
  ) =>
      withRequestChain(chain);

  /// Sets a [NetworkFilterChain] for received message filtering (WS alias).
  ISpectWSInterceptorSettingsBuilder withReceivedChain(
    NetworkFilterChain<ISpectLogData> chain,
  ) =>
      withResponseChain(chain);

  @override
  ISpectWSInterceptorSettings build() => ISpectWSInterceptorSettings(
        enabled: enabled,
        enableRedaction: enableRedaction,
        logRequests: logRequests,
        logResponses: logResponses,
        printReceivedData: printResponseData,
        printReceivedHeaders: printResponseHeaders,
        printReceivedMessage: printResponseMessage,
        printErrorData: printErrorData,
        printErrorMessage: printErrorMessage,
        printStateData: printStateData,
        printSentData: printRequestData,
        printSentHeaders: printRequestHeaders,
        sentPen: requestPen,
        receivedPen: responsePen,
        errorPen: errorPen,
        sentFilter: requestFilter,
        receivedFilter: responseFilter,
        errorFilter: errorFilter,
        sentChain: requestChain,
        receivedChain: responseChain,
        errorChain: errorChain,
      );
}
