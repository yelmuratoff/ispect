import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

/// `ISpectHttpInterceptor` settings and customization.
class ISpectHttpInterceptorSettings extends BaseNetworkInterceptorSettings {
  const ISpectHttpInterceptorSettings({
    super.enabled,
    super.enableRedaction,
    super.printResponseData,
    super.printResponseHeaders,
    super.printResponseMessage,
    super.printErrorData,
    super.printErrorHeaders,
    super.printErrorMessage,
    super.printRequestData,
    super.printRequestHeaders,
    super.requestPen,
    super.responsePen,
    super.errorPen,
    this.requestFilter,
    this.responseFilter,
    this.errorFilter,
  });

  /// For request filtering.
  /// You can add your custom logic to log only specific HTTP requests.
  final bool Function(BaseRequest request)? requestFilter;

  /// For response filtering.
  /// You can add your custom logic to log only specific HTTP responses.
  final bool Function(BaseResponse response)? responseFilter;

  /// For error filtering.
  /// You can add your custom logic to log only specific HTTP errors.
  final bool Function(BaseResponse response)? errorFilter;

  @override
  ISpectHttpInterceptorSettings copyWith({
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
    bool Function(BaseRequest request)? requestFilter,
    bool Function(BaseResponse response)? responseFilter,
    bool Function(BaseResponse response)? errorFilter,
  }) =>
      ISpectHttpInterceptorSettings(
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
