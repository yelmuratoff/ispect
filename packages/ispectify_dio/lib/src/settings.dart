// ignore_for_file: deprecated_member_use_from_same_package
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
    @Deprecated('Use requestChain instead') this.requestFilter,
    @Deprecated('Use responseChain instead') this.responseFilter,
    @Deprecated('Use errorChain instead') this.errorFilter,
    this.requestChain,
    this.responseChain,
    this.errorChain,
  });

  /// For request filtering.
  /// You can add your custom logic to log only specific HTTP requests.
  @Deprecated('Use requestChain instead')
  final bool Function(RequestOptions requestOptions)? requestFilter;

  /// For response filtering.
  /// You can add your custom logic to log only specific HTTP responses.
  @Deprecated('Use responseChain instead')
  final bool Function(Response<dynamic> response)? responseFilter;

  /// For error filtering.
  /// You can add your custom logic to log only specific Dio errors.
  @Deprecated('Use errorChain instead')
  final bool Function(DioException response)? errorFilter;

  /// Filter chain for requests. Takes priority over [requestFilter].
  final NetworkFilterChain<RequestOptions>? requestChain;

  /// Filter chain for responses. Takes priority over [responseFilter].
  final NetworkFilterChain<Response<dynamic>>? responseChain;

  /// Filter chain for errors. Takes priority over [errorFilter].
  final NetworkFilterChain<DioException>? errorChain;

  /// Returns `true` when the request should be logged.
  ///
  /// [requestChain] takes priority over the legacy [requestFilter].
  bool shouldProcessRequest(RequestOptions value) {
    if (requestChain != null) return requestChain!.apply(value);
    return requestFilter?.call(value) ?? true;
  }

  /// Returns `true` when the response should be logged.
  ///
  /// [responseChain] takes priority over the legacy [responseFilter].
  bool shouldProcessResponse(Response<dynamic> value) {
    if (responseChain != null) return responseChain!.apply(value);
    return responseFilter?.call(value) ?? true;
  }

  /// Returns `true` when the error should be logged.
  ///
  /// [errorChain] takes priority over the legacy [errorFilter].
  bool shouldProcessError(DioException value) {
    if (errorChain != null) return errorChain!.apply(value);
    return errorFilter?.call(value) ?? true;
  }

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
    @Deprecated('Use requestChain instead')
    bool Function(RequestOptions requestOptions)? requestFilter,
    @Deprecated('Use responseChain instead')
    bool Function(Response<dynamic> response)? responseFilter,
    @Deprecated('Use errorChain instead')
    bool Function(DioException response)? errorFilter,
    NetworkFilterChain<RequestOptions>? requestChain,
    NetworkFilterChain<Response<dynamic>>? responseChain,
    NetworkFilterChain<DioException>? errorChain,
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
        requestChain: requestChain ?? this.requestChain,
        responseChain: responseChain ?? this.responseChain,
        errorChain: errorChain ?? this.errorChain,
      );
}
