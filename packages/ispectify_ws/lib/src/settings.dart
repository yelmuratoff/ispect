import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

/// `ISpectWSInterceptorSettings` settings and customization
class ISpectWSInterceptorSettings {
  const ISpectWSInterceptorSettings({
    this.enabled = true,
    this.printResponseData = true,
    this.printResponseMessage = true,
    this.printErrorData = true,
    this.printErrorMessage = true,
    this.printRequestData = true,
    this.printRequestHeaders = false,
    this.requestPen,
    this.responsePen,
    this.errorPen,
    this.requestFilter,
    this.responseFilter,
    this.errorFilter,
  });

  // Print HTTP logger if true
  final bool enabled;

  /// Print response data if true
  final bool printResponseData;

  /// Print response status message if true
  final bool printResponseMessage;

  /// Print error data if true
  final bool printErrorData;

  /// Print error message if true
  final bool printErrorMessage;

  /// Print request data if true
  final bool printRequestData;

  /// Print request headers if true
  final bool printRequestHeaders;

  /// Field to set custom http request console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? requestPen;

  /// Field to set custom http response console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? responsePen;

  /// Field to set custom http error console logs color
  ///```
  ///// Red color
  ///final redPen = AnsiPen()..red();
  ///
  ///// Blue color
  ///final redPen = AnsiPen()..blue();
  ///```
  /// More details in `AnsiPen` docs
  final AnsiPen? errorPen;

  final bool Function(WSRequestLog request)? requestFilter;

  final bool Function(WSResponseLog response)? responseFilter;

  final bool Function(WSErrorLog response)? errorFilter;
}
