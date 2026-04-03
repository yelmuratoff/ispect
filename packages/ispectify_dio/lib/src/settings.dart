import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';

/// `ISpectDioInterceptor` settings and customization.
class ISpectDioInterceptorSettings extends BaseNetworkInterceptorSettings {
  const ISpectDioInterceptorSettings({
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
  final bool Function(RequestOptions requestOptions)? requestFilter;

  /// For response filtering.
  /// You can add your custom logic to log only specific HTTP responses.
  final bool Function(Response<dynamic> response)? responseFilter;

  /// For error filtering.
  /// You can add your custom logic to log only specific Dio errors.
  final bool Function(DioException response)? errorFilter;

  @override
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
