// ignore_for_file: deprecated_member_use_from_same_package
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
  final bool Function(BaseRequest request)? requestFilter;

  /// For response filtering.
  /// You can add your custom logic to log only specific HTTP responses.
  @Deprecated('Use responseChain instead')
  final bool Function(BaseResponse response)? responseFilter;

  /// For error filtering.
  /// You can add your custom logic to log only specific HTTP errors.
  @Deprecated('Use errorChain instead')
  final bool Function(BaseResponse response)? errorFilter;

  /// Filter chain for requests. Takes priority over [requestFilter].
  final NetworkFilterChain<BaseRequest>? requestChain;

  /// Filter chain for responses. Takes priority over [responseFilter].
  final NetworkFilterChain<BaseResponse>? responseChain;

  /// Filter chain for errors. Takes priority over [errorFilter].
  final NetworkFilterChain<BaseResponse>? errorChain;

  /// Returns `true` when the request should be logged.
  bool shouldProcessRequest(BaseRequest value) {
    if (requestChain != null) return requestChain!.apply(value);
    return requestFilter?.call(value) ?? true;
  }

  /// Returns `true` when the response should be logged.
  bool shouldProcessResponse(BaseResponse value) {
    if (responseChain != null) return responseChain!.apply(value);
    return responseFilter?.call(value) ?? true;
  }

  /// Returns `true` when the error should be logged.
  bool shouldProcessError(BaseResponse value) {
    if (errorChain != null) return errorChain!.apply(value);
    return errorFilter?.call(value) ?? true;
  }

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
    @Deprecated('Use requestChain instead')
    bool Function(BaseRequest request)? requestFilter,
    @Deprecated('Use responseChain instead')
    bool Function(BaseResponse response)? responseFilter,
    @Deprecated('Use errorChain instead')
    bool Function(BaseResponse response)? errorFilter,
    NetworkFilterChain<BaseRequest>? requestChain,
    NetworkFilterChain<BaseResponse>? responseChain,
    NetworkFilterChain<BaseResponse>? errorChain,
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
        requestChain: requestChain ?? this.requestChain,
        responseChain: responseChain ?? this.responseChain,
        errorChain: errorChain ?? this.errorChain,
      );
}
