// ignore_for_file: deprecated_member_use_from_same_package
import 'package:ispectify/ispectify.dart';

/// WebSocket interceptor settings.
///
/// Extends [BaseNetworkInterceptorSettings] to reuse shared fields
/// (`enabled`, `enableRedaction`, pens, print toggles) while providing
/// WS-specific convenience aliases (`printSentData`, `sentPen`, etc.).
///
/// **v5.0 breaking change:** Filter function signatures changed from
/// typed log subclasses to `ISpectLogData`. Filters now receive the
/// actual log data instead of `null`.
class ISpectWSInterceptorSettings extends BaseNetworkInterceptorSettings {
  const ISpectWSInterceptorSettings({
    super.enabled,
    super.enableRedaction,
    bool printReceivedData = true,
    bool printReceivedMessage = true,
    super.printErrorData,
    super.printErrorMessage,
    bool printSentData = true,
    bool printReceivedHeaders = false,
    bool printSentHeaders = false,
    AnsiPen? sentPen,
    AnsiPen? receivedPen,
    super.errorPen,
    @Deprecated('Use sentChain instead') this.sentFilter,
    @Deprecated('Use receivedChain instead') this.receivedFilter,
    @Deprecated('Use errorChain instead') this.errorFilter,
    this.sentChain,
    this.receivedChain,
    this.errorChain,
  }) : super(
          printRequestData: printSentData,
          printRequestHeaders: printSentHeaders,
          printResponseData: printReceivedData,
          printResponseHeaders: printReceivedHeaders,
          printResponseMessage: printReceivedMessage,
          printErrorHeaders: false,
          requestPen: sentPen,
          responsePen: receivedPen,
        );

  /// Filter for sent messages. Return `false` to suppress logging.
  @Deprecated('Use sentChain instead')
  final bool Function(ISpectLogData data)? sentFilter;

  /// Filter for received messages. Return `false` to suppress logging.
  @Deprecated('Use receivedChain instead')
  final bool Function(ISpectLogData data)? receivedFilter;

  /// Filter for error events. Return `false` to suppress logging.
  @Deprecated('Use errorChain instead')
  final bool Function(ISpectLogData data)? errorFilter;

  /// Filter chain for sent messages. Takes priority over [sentFilter].
  final NetworkFilterChain<ISpectLogData>? sentChain;

  /// Filter chain for received messages. Takes priority over [receivedFilter].
  final NetworkFilterChain<ISpectLogData>? receivedChain;

  /// Filter chain for errors. Takes priority over [errorFilter].
  final NetworkFilterChain<ISpectLogData>? errorChain;

  /// Returns `true` when the sent message should be logged.
  bool shouldProcessSent(ISpectLogData value) {
    if (sentChain != null) return sentChain!.apply(value);
    return sentFilter?.call(value) ?? true;
  }

  /// Returns `true` when the received message should be logged.
  bool shouldProcessReceived(ISpectLogData value) {
    if (receivedChain != null) return receivedChain!.apply(value);
    return receivedFilter?.call(value) ?? true;
  }

  /// Returns `true` when the error should be logged.
  bool shouldProcessError(ISpectLogData value) {
    if (errorChain != null) return errorChain!.apply(value);
    return errorFilter?.call(value) ?? true;
  }

  bool get printSentData => printRequestData;
  bool get printSentHeaders => printRequestHeaders;
  bool get printReceivedData => printResponseData;
  bool get printReceivedHeaders => printResponseHeaders;
  bool get printReceivedMessage => printResponseMessage;
  AnsiPen? get sentPen => requestPen;
  AnsiPen? get receivedPen => responsePen;

  /// Creates a copy with updated values.
  ///
  /// Accepts both WS-specific names (`printSentData`, `printReceivedData`,
  /// `sentPen`, `receivedPen`, etc.) and the base-interface aliases
  /// (`printRequestData`, `printResponseData`, `requestPen`, `responsePen`).
  /// WS-specific names take precedence when both are provided.
  ///
  /// `printErrorHeaders` is accepted for interface compatibility but has no
  /// effect — WebSocket logging never prints error headers.
  @override
  ISpectWSInterceptorSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    // WS-specific names (preferred)
    bool? printSentData,
    bool? printSentHeaders,
    bool? printReceivedData,
    bool? printReceivedHeaders,
    bool? printReceivedMessage,
    bool? printErrorData,
    bool? printErrorMessage,
    AnsiPen? sentPen,
    AnsiPen? receivedPen,
    AnsiPen? errorPen,
    // Base-interface aliases (used by BaseNetworkInterceptor.configure)
    bool? printRequestData,
    bool? printRequestHeaders,
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    // Accepted for interface compatibility; has no effect on WS.
    // ignore: avoid_unused_constructor_parameters
    bool? printErrorHeaders,
    @Deprecated('Use sentChain instead')
    bool Function(ISpectLogData data)? sentFilter,
    @Deprecated('Use receivedChain instead')
    bool Function(ISpectLogData data)? receivedFilter,
    @Deprecated('Use errorChain instead')
    bool Function(ISpectLogData data)? errorFilter,
    NetworkFilterChain<ISpectLogData>? sentChain,
    NetworkFilterChain<ISpectLogData>? receivedChain,
    NetworkFilterChain<ISpectLogData>? errorChain,
  }) =>
      ISpectWSInterceptorSettings(
        enabled: enabled ?? this.enabled,
        enableRedaction: enableRedaction ?? this.enableRedaction,
        printSentData: printSentData ?? printRequestData ?? this.printSentData,
        printSentHeaders:
            printSentHeaders ?? printRequestHeaders ?? this.printSentHeaders,
        printReceivedData:
            printReceivedData ?? printResponseData ?? this.printReceivedData,
        printReceivedHeaders: printReceivedHeaders ??
            printResponseHeaders ??
            this.printReceivedHeaders,
        printReceivedMessage: printReceivedMessage ??
            printResponseMessage ??
            this.printReceivedMessage,
        printErrorData: printErrorData ?? this.printErrorData,
        printErrorMessage: printErrorMessage ?? this.printErrorMessage,
        sentPen: sentPen ?? requestPen ?? this.sentPen,
        receivedPen: receivedPen ?? responsePen ?? this.receivedPen,
        errorPen: errorPen ?? this.errorPen,
        sentFilter: sentFilter ?? this.sentFilter,
        receivedFilter: receivedFilter ?? this.receivedFilter,
        errorFilter: errorFilter ?? this.errorFilter,
        sentChain: sentChain ?? this.sentChain,
        receivedChain: receivedChain ?? this.receivedChain,
        errorChain: errorChain ?? this.errorChain,
      );
}
