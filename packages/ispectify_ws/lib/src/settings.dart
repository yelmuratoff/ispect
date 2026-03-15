import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

/// `ISpectWSInterceptorSettings` settings and customization
class ISpectWSInterceptorSettings implements NetworkLogPrintOptions {
  const ISpectWSInterceptorSettings({
    this.enabled = true,
    this.enableRedaction = true,
    this.printReceivedData = true,
    this.printReceivedMessage = true,
    this.printErrorData = true,
    this.printErrorMessage = true,
    this.printSentData = true,
    this.printReceivedHeaders = false,
    this.printSentHeaders = false,
    AnsiPen? sentPen,
    AnsiPen? receivedPen,
    AnsiPen? errorPen,
    this.sentFilter,
    this.receivedFilter,
    this.errorFilter,
  })  : _sentPen = sentPen,
        _receivedPen = receivedPen,
        _errorPen = errorPen;

  /// Print WS logger if true
  final bool enabled;

  /// Enable sensitive data redaction if true (default: true)
  final bool enableRedaction;

  /// Print response data if true
  final bool printReceivedData;

  /// Print response status message if true
  final bool printReceivedMessage;

  /// Print error data if true
  @override
  final bool printErrorData;

  /// Print error message if true
  @override
  final bool printErrorMessage;

  /// Print request data if true
  final bool printSentData;

  /// Print response headers if true
  final bool printReceivedHeaders;

  /// Print request headers if true
  final bool printSentHeaders;

  /// Field to set custom ws sent console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? _sentPen;

  /// Field to set custom ws received console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? _receivedPen;

  /// Field to set custom ws error console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? _errorPen;

  final bool Function(WSSentLog request)? sentFilter;

  final bool Function(WSReceivedLog response)? receivedFilter;

  final bool Function(WSErrorLog response)? errorFilter;

  AnsiPen? get sentPen => _sentPen;

  AnsiPen? get receivedPen => _receivedPen;

  @override
  bool get printRequestData => printSentData;

  @override
  bool get printRequestHeaders => printSentHeaders;

  @override
  bool get printResponseData => printReceivedData;

  @override
  bool get printResponseHeaders => printReceivedHeaders;

  @override
  bool get printResponseMessage => printReceivedMessage;

  @override
  bool get printErrorHeaders => false;

  @override
  AnsiPen? get errorPen => _errorPen;

  @override
  AnsiPen? get requestPen => _sentPen;

  @override
  AnsiPen? get responsePen => _receivedPen;

  /// Creates a copy of this settings with the given fields replaced.
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
    bool Function(WSSentLog request)? sentFilter,
    bool Function(WSReceivedLog response)? receivedFilter,
    bool Function(WSErrorLog response)? errorFilter,
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
        sentPen: sentPen ?? _sentPen,
        receivedPen: receivedPen ?? _receivedPen,
        errorPen: errorPen ?? _errorPen,
        sentFilter: sentFilter ?? this.sentFilter,
        receivedFilter: receivedFilter ?? this.receivedFilter,
        errorFilter: errorFilter ?? this.errorFilter,
      );
}
