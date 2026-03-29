// ignore_for_file: avoid_returning_this
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

/// Builder for [ISpectWSInterceptorSettings] providing fluent API.
class ISpectWSInterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<
        ISpectWSInterceptorSettingsBuilder> {
  ISpectWSInterceptorSettingsBuilder();

  factory ISpectWSInterceptorSettingsBuilder.development() =>
      ISpectWSInterceptorSettingsBuilder()..applyDevelopmentDefaults();

  factory ISpectWSInterceptorSettingsBuilder.production() =>
      ISpectWSInterceptorSettingsBuilder()..applyProductionDefaults();

  factory ISpectWSInterceptorSettingsBuilder.staging() =>
      ISpectWSInterceptorSettingsBuilder()..applyStagingDefaults();

  factory ISpectWSInterceptorSettingsBuilder.disabled() =>
      ISpectWSInterceptorSettingsBuilder()..enabled = false;

  bool Function(ISpectLogData? data)? _sentFilter;
  bool Function(ISpectLogData? data)? _receivedFilter;
  bool Function(ISpectLogData? data)? _errorFilter;

  ISpectWSInterceptorSettingsBuilder withSentFilter(
    bool Function(ISpectLogData? data) filter,
  ) {
    _sentFilter = filter;
    return this;
  }

  ISpectWSInterceptorSettingsBuilder withReceivedFilter(
    bool Function(ISpectLogData? data) filter,
  ) {
    _receivedFilter = filter;
    return this;
  }

  ISpectWSInterceptorSettingsBuilder withErrorFilter(
    bool Function(ISpectLogData? data) filter,
  ) {
    _errorFilter = filter;
    return this;
  }

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
        sentFilter: _sentFilter,
        receivedFilter: _receivedFilter,
        errorFilter: _errorFilter,
      );
}
