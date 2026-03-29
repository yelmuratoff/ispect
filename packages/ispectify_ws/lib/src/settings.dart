import 'package:ispectify/ispectify.dart';

/// WebSocket interceptor settings.
///
/// Extends [BaseNetworkInterceptorSettings] to reuse shared fields
/// (`enabled`, `enableRedaction`, pens, print toggles) while providing
/// WS-specific convenience aliases (`printSentData`, `sentPen`, etc.).
///
/// **v5.0 breaking change:** Filter function signatures changed from
/// typed log subclasses to nullable `ISpectLogData?`.
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
    this.sentFilter,
    this.receivedFilter,
    this.errorFilter,
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
  final bool Function(ISpectLogData? data)? sentFilter;

  /// Filter for received messages. Return `false` to suppress logging.
  final bool Function(ISpectLogData? data)? receivedFilter;

  /// Filter for error events. Return `false` to suppress logging.
  final bool Function(ISpectLogData? data)? errorFilter;

  bool get printSentData => printRequestData;
  bool get printSentHeaders => printRequestHeaders;
  bool get printReceivedData => printResponseData;
  bool get printReceivedHeaders => printResponseHeaders;
  bool get printReceivedMessage => printResponseMessage;
  AnsiPen? get sentPen => requestPen;
  AnsiPen? get receivedPen => responsePen;

  ISpectWSInterceptorSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    bool? printReceivedData,
    bool? printReceivedMessage,
    bool? printErrorData,
    bool? printErrorMessage,
    bool? printSentData,
    bool? printReceivedHeaders,
    bool? printSentHeaders,
    AnsiPen? sentPen,
    AnsiPen? receivedPen,
    AnsiPen? errorPen,
    bool Function(ISpectLogData? data)? sentFilter,
    bool Function(ISpectLogData? data)? receivedFilter,
    bool Function(ISpectLogData? data)? errorFilter,
  }) =>
      ISpectWSInterceptorSettings(
        enabled: enabled ?? this.enabled,
        enableRedaction: enableRedaction ?? this.enableRedaction,
        printReceivedData: printReceivedData ?? this.printReceivedData,
        printReceivedMessage: printReceivedMessage ?? this.printReceivedMessage,
        printErrorData: printErrorData ?? this.printErrorData,
        printErrorMessage: printErrorMessage ?? this.printErrorMessage,
        printSentData: printSentData ?? this.printSentData,
        printReceivedHeaders: printReceivedHeaders ?? this.printReceivedHeaders,
        printSentHeaders: printSentHeaders ?? this.printSentHeaders,
        sentPen: sentPen ?? this.sentPen,
        receivedPen: receivedPen ?? this.receivedPen,
        errorPen: errorPen ?? this.errorPen,
        sentFilter: sentFilter ?? this.sentFilter,
        receivedFilter: receivedFilter ?? this.receivedFilter,
        errorFilter: errorFilter ?? this.errorFilter,
      );
}
