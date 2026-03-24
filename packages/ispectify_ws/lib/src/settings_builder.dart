// ignore_for_file: avoid_returning_this
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

/// Builder for [ISpectWSInterceptorSettings] providing fluent API.
///
/// {@tool snippet}
/// ```dart
/// final settings = ISpectWSInterceptorSettingsBuilder()
///   .withRequestHeaders()
///   .withResponseHeaders()
///   .withRedaction()
///   .build();
/// ```
/// {@end-tool}
class ISpectWSInterceptorSettingsBuilder
    extends BaseNetworkInterceptorSettingsBuilder<
        ISpectWSInterceptorSettingsBuilder> {
  /// Creates a builder with default settings (moderate verbosity).
  ISpectWSInterceptorSettingsBuilder();

  /// Development: verbose logging, redaction enabled.
  factory ISpectWSInterceptorSettingsBuilder.development() =>
      ISpectWSInterceptorSettingsBuilder()..applyDevelopmentDefaults();

  /// Production: errors only, redaction enabled.
  factory ISpectWSInterceptorSettingsBuilder.production() =>
      ISpectWSInterceptorSettingsBuilder()..applyProductionDefaults();

  /// Staging: requests + errors, redaction enabled.
  factory ISpectWSInterceptorSettingsBuilder.staging() =>
      ISpectWSInterceptorSettingsBuilder()..applyStagingDefaults();

  /// Logging disabled.
  factory ISpectWSInterceptorSettingsBuilder.disabled() =>
      ISpectWSInterceptorSettingsBuilder()..enabled = false;

  bool Function(WSSentLog request)? _sentFilter;
  bool Function(WSReceivedLog response)? _receivedFilter;
  bool Function(WSErrorLog response)? _errorFilter;

  /// Sets a custom sent message filter.
  ///
  /// Only sent messages where the filter returns `true` will be logged.
  ISpectWSInterceptorSettingsBuilder withSentFilter(
    bool Function(WSSentLog) filter,
  ) {
    _sentFilter = filter;
    return this;
  }

  /// Sets a custom received message filter.
  ///
  /// Only received messages where the filter returns `true` will be logged.
  ISpectWSInterceptorSettingsBuilder withReceivedFilter(
    bool Function(WSReceivedLog) filter,
  ) {
    _receivedFilter = filter;
    return this;
  }

  /// Sets a custom error filter.
  ///
  /// Only errors where the filter returns `true` will be logged.
  ISpectWSInterceptorSettingsBuilder withErrorFilter(
    bool Function(WSErrorLog) filter,
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
