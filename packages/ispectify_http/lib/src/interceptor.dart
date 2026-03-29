import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

/// HTTP client interceptor that logs requests/responses via the trace API.
class ISpectHttpInterceptor extends InterceptorContract
    with BaseNetworkInterceptor {
  ISpectHttpInterceptor({
    ISpectLogger? logger,
    ISpectHttpInterceptorSettings settings =
        const ISpectHttpInterceptorSettings(),
    RedactionService? redactor,
  })  : _settings = settings,
        _logger = logger ?? ISpectLogger() {
    if (redactor != null) this.redactor = redactor;
  }

  final ISpectLogger _logger;

  @override
  ISpectLogger get logger => _logger;

  ISpectHttpInterceptorSettings get settings => _settings;
  ISpectHttpInterceptorSettings _settings;

  final Expando<String> _requestIds = Expando<String>('ispect_rid');
  final Expando<Stopwatch> _stopwatches = Expando<Stopwatch>('ispect_sw');

  @override
  bool get enableRedaction => settings.enableRedaction;

  static const _noRedactConfig = ISpectTraceConfig(redact: false);

  void configure({
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    bool? enableRedaction,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
    RedactionService? redactor,
  }) {
    _settings = _settings.copyWith(
      printRequestData: printRequestData,
      printRequestHeaders: printRequestHeaders,
      printResponseData: printResponseData,
      printErrorData: printErrorData,
      printErrorHeaders: printErrorHeaders,
      printErrorMessage: printErrorMessage,
      printResponseHeaders: printResponseHeaders,
      printResponseMessage: printResponseMessage,
      enableRedaction: enableRedaction,
      requestPen: requestPen,
      responsePen: responsePen,
      errorPen: errorPen,
    );
    if (redactor != null) this.redactor = redactor;
  }

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (!shouldProcess(
      enabled: settings.enabled,
      filter: settings.requestFilter,
      value: request,
    )) {
      return request;
    }

    final requestId = generateTraceId();
    _requestIds[request] = requestId;
    _stopwatches[request] = Stopwatch()..start();

    final useRedaction = settings.enableRedaction;
    final (:url, path: _) = redactUrlAndPath(
      request.url,
      useRedaction: useRedaction,
    );

    _logger.trace(
      category: networkCategory,
      source: 'http',
      operation: request.method,
      target: url,
      logKey: ISpectLogType.httpRequest.key,
      correlationId: requestId,
      success: true,
      config: useRedaction ? null : _noRedactConfig,
      meta: {
        'requestId': requestId,
        'requestData': HttpRequestData(request).toJson(
          redactor: useRedaction ? redactor : null,
        ),
      },
    );
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final isErrorResponse =
        response.statusCode >= 400 && response.statusCode < 600;

    if (!isErrorResponse &&
        !shouldProcess(
          enabled: settings.enabled,
          filter: settings.responseFilter,
          value: response,
        )) {
      return response;
    }
    if (isErrorResponse &&
        !shouldProcess(
          enabled: settings.enabled,
          filter: settings.errorFilter,
          value: response,
        )) {
      return response;
    }

    final request = response.request;
    final requestId = request != null ? _requestIds[request] : null;
    final sw = request != null ? _stopwatches[request] : null;
    sw?.stop();

    final useRedaction = settings.enableRedaction;
    final requestUrl = request?.url;
    final (:url, path: _) = requestUrl != null
        ? redactUrlAndPath(requestUrl, useRedaction: useRedaction)
        : (url: '', path: '');

    final responseData = HttpResponseData(
      baseResponse: response,
      requestData: HttpRequestData(request),
      response: response is Response ? response : null,
      multipartRequest: request is MultipartRequest ? request : null,
      preDecodedBody: _responseBodyPayload(
        response,
        useRedaction,
        include: isErrorResponse
            ? settings.printErrorData
            : settings.printResponseData,
      ),
    );

    _logger.trace(
      category: networkCategory,
      source: 'http',
      operation: request?.method ?? 'UNKNOWN',
      target: url,
      logKey: isErrorResponse
          ? ISpectLogType.httpError.key
          : ISpectLogType.httpResponse.key,
      correlationId: requestId,
      success: !isErrorResponse,
      duration: sw?.elapsed,
      config: useRedaction ? null : _noRedactConfig,
      meta: {
        if (requestId != null) 'requestId': requestId,
        'statusCode': response.statusCode,
        'responseData': responseData.toJson(
          redactor: useRedaction ? redactor : null,
        ),
      },
    );

    return response;
  }

  Object? _responseBodyPayload(
    BaseResponse response,
    bool useRedaction, {
    required bool include,
  }) {
    if (!include) return null;
    if (response is! Response || response.body.isEmpty) return null;

    return payload.body(
      response.body,
      enableRedaction: useRedaction,
      normalizer: NetworkPayloadSanitizer.decodeJsonGracefully,
    );
  }
}
