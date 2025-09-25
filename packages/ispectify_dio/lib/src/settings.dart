import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';

/// `ISpectDioInterceptor` settings and customization
class ISpectDioInterceptorSettings {
  const ISpectDioInterceptorSettings({
    this.enabled = true,
    this.enableRedaction = false,
    this.printResponseData = true,
    this.printResponseHeaders = false,
    this.printResponseMessage = true,
    this.printErrorData = true,
    this.printErrorHeaders = true,
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

  // Print Dio logger if true
  final bool enabled;

  /// Enable sensitive data redaction if true (default: true)
  final bool enableRedaction;

  /// Print `response.data` if true
  final bool printResponseData;

  /// Print `response.headers` if true
  final bool printResponseHeaders;

  /// Print `response.statusMessage` if true
  final bool printResponseMessage;

  /// Print `error.response.data` if true
  final bool printErrorData;

  /// Print `error.response.headers` if true
  final bool printErrorHeaders;

  /// Print `error.message` if true
  final bool printErrorMessage;

  /// Print `request.data` if true
  final bool printRequestData;

  /// Print `request.headers` if true
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

  /// For request filtering.
  /// You can add your custom logic to log only specific HTTP requests `RequestOptions`.
  final bool Function(RequestOptions requestOptions)? requestFilter;

  /// For response filtering.
  /// You can add your custom logic to log only specific HTTP responses `Response`.
  final bool Function(Response<dynamic> response)? responseFilter;

  /// For error filtering.
  /// You can add your custom logic to log only specific Dio error `DioException`.
  final bool Function(DioException response)? errorFilter;

  ISpectDioInterceptorSettings copyWith({
    bool? enabled,
    bool? enableRedaction,
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
    bool Function(RequestOptions requestOptions)? requestFilter,
    bool Function(Response<dynamic> response)? responseFilter,
    bool Function(DioException response)? errorFilter,
  }) =>
      ISpectDioInterceptorSettings(
        enabled: enabled ?? this.enabled,
        enableRedaction: enableRedaction ?? this.enableRedaction,
        printResponseData: printResponseData ?? this.printResponseData,
        printResponseHeaders: printResponseHeaders ?? this.printResponseHeaders,
        printResponseMessage: printResponseMessage ?? this.printResponseMessage,
        printErrorData: printErrorData ?? this.printErrorData,
        printErrorHeaders: printErrorHeaders ?? this.printErrorHeaders,
        printErrorMessage: printErrorMessage ?? this.printErrorMessage,
        printRequestData: printRequestData ?? this.printRequestData,
        printRequestHeaders: printRequestHeaders ?? this.printRequestHeaders,
        requestPen: requestPen ?? this.requestPen,
        responsePen: responsePen ?? this.responsePen,
        errorPen: errorPen ?? this.errorPen,
        requestFilter: requestFilter ?? this.requestFilter,
        responseFilter: responseFilter ?? this.responseFilter,
        errorFilter: errorFilter ?? this.errorFilter,
      );
}
