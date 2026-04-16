import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

/// HTTP client interceptor that logs requests/responses via the trace API.
class ISpectHttpInterceptor extends InterceptorContract
    with
        NetworkLoggerMixin,
        NetworkRedactionMixin,
        NetworkConfigurationMixin,
        BaseNetworkInterceptor {
  ISpectHttpInterceptor({
    ISpectLogger? logger,
    ISpectHttpInterceptorSettings settings =
        const ISpectHttpInterceptorSettings(),
    RedactionService? redactor,
  })  : _settings = settings,
        _logger = logger ?? ISpectLogger(),
        _redactor = redactor ?? RedactionService();

  final ISpectLogger _logger;
  final RedactionService _redactor;

  @override
  ISpectLogger get logger => _logger;

  @override
  RedactionService get redactor => _redactor;

  ISpectHttpInterceptorSettings get settings => _settings;
  ISpectHttpInterceptorSettings _settings;

  final Expando<String> _requestIds = Expando<String>('ispect_rid');
  final Expando<Stopwatch> _stopwatches = Expando<Stopwatch>('ispect_sw');

  @override
  bool get enableRedaction => settings.enableRedaction;

  @override
  BaseNetworkInterceptorSettings get configurableSettings => _settings;

  @override
  void applyConfigurableSettings(BaseNetworkInterceptorSettings updated) {
    _settings = updated as ISpectHttpInterceptorSettings;
  }

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (!settings.enabled || !settings.shouldProcessRequest(request)) {
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

    final requestDataJson = HttpRequestData(request).toJson();
    if (useRedaction) HttpRequestData.redact(requestDataJson, redactor);

    _logger.httpRequest(
      source: 'http',
      operation: request.method,
      target: url,
      correlationId: requestId,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
      consoleMessage: buildNetworkConsoleMessage(
        source: 'http',
        operation: request.method,
        target: url,
        printBody: settings.printRequestData,
        printHeaders: settings.printRequestHeaders,
        body: requestDataJson[NetworkJsonKeys.data],
        headers: BaseNetworkInterceptor.asStringMap(
          requestDataJson[NetworkJsonKeys.headers],
        ),
      ),
      meta: {
        'request-id': requestId,
        'request-data': requestDataJson,
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

    if (!settings.enabled) return response;
    if (!isErrorResponse && !settings.shouldProcessResponse(response)) {
      return response;
    }
    if (isErrorResponse && !settings.shouldProcessError(response)) {
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

    final responseDataJson = responseData.toJson();
    if (useRedaction) HttpResponseData.redact(responseDataJson, redactor);
    final sharedMeta = <String, Object?>{
      if (requestId != null) 'request-id': requestId,
      'status-code': response.statusCode,
      'response-data': responseDataJson,
    };

    final method = request?.method ?? 'UNKNOWN';

    if (isErrorResponse) {
      _logger.httpError(
        source: 'http',
        operation: method,
        target: url,
        correlationId: requestId,
        duration: sw?.elapsed,
        config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
        consoleMessage: buildNetworkConsoleMessage(
          source: 'http',
          operation: method,
          target: url,
          duration: sw?.elapsed,
          success: false,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          body: responseDataJson[NetworkJsonKeys.body],
          headers: BaseNetworkInterceptor.asStringMap(
            responseDataJson[NetworkJsonKeys.headers],
          ),
          printStatusCode: true,
          printStatusMessage: settings.printErrorMessage,
          printBody: settings.printErrorData,
          printHeaders: settings.printErrorHeaders,
        ),
        meta: sharedMeta,
      );
    } else {
      _logger.httpResponse(
        source: 'http',
        operation: method,
        target: url,
        correlationId: requestId,
        duration: sw?.elapsed,
        config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
        consoleMessage: buildNetworkConsoleMessage(
          source: 'http',
          operation: method,
          target: url,
          duration: sw?.elapsed,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          body: responseDataJson[NetworkJsonKeys.body],
          headers: BaseNetworkInterceptor.asStringMap(
            responseDataJson[NetworkJsonKeys.headers],
          ),
          printStatusCode: true,
          printStatusMessage: settings.printResponseMessage,
          printBody: settings.printResponseData,
          printHeaders: settings.printResponseHeaders,
        ),
        meta: sharedMeta,
      );
    }

    return response;
  }

  Object? _responseBodyPayload(
    BaseResponse response,
    bool useRedaction, {
    required bool include,
  }) {
    if (!include) return null;
    if (response is! Response || response.body.isEmpty) return null;

    return NetworkPayloadSanitizer.decodeJsonGracefully(response.body);
  }
}
