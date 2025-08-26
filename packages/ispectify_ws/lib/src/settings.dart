import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

/// `ISpectWSInterceptorSettings` settings and customization
class ISpectWSInterceptorSettings {
  const ISpectWSInterceptorSettings({
    this.enabled = true,
    this.enableRedaction = true,
    this.printReceivedData = true,
    this.printReceivedMessage = true,
    this.printErrorData = true,
    this.printErrorMessage = true,
    this.printSentData = true,
    this.printReceivedHeaders = false,
    this.sentPen,
    this.receivedPen,
    this.errorPen,
    this.sentFilter,
    this.receivedFilter,
    this.errorFilter,
  });

  // Print HTTP logger if true
  final bool enabled;

  /// Enable sensitive data redaction if true (default: true)
  final bool enableRedaction;

  /// Print response data if true
  final bool printReceivedData;

  /// Print response status message if true
  final bool printReceivedMessage;

  /// Print error data if true
  final bool printErrorData;

  /// Print error message if true
  final bool printErrorMessage;

  /// Print request data if true
  final bool printSentData;

  /// Print request headers if true
  final bool printReceivedHeaders;

  /// Field to set custom ws sent console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? sentPen;

  /// Field to set custom ws received console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? receivedPen;

  /// Field to set custom ws error console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? errorPen;

  final bool Function(WSSentLog request)? sentFilter;

  final bool Function(WSReceivedLog response)? receivedFilter;

  final bool Function(WSErrorLog response)? errorFilter;
}
