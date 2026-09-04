import 'dart:async';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

/// HTTP client interceptor that logs requests/responses via the trace API.
///
/// Register this interceptor **last** in the `interceptors` list. Correlation
/// between a request and its response is keyed on the `BaseRequest` instance,
/// and `http_interceptor` lets each interceptor return a *new* request object
/// (`current = await interceptor.interceptRequest(...)`). Placing this last
/// guarantees it observes the same final request object on both the request and
/// response legs; an interceptor registered after it that rebuilds the request
/// would otherwise leave the response uncorrelated (shown as "Pending").
class ISpectHttpInterceptor
    with
        NetworkLoggerMixin,
        NetworkRedactionMixin,
        NetworkConfigurationMixin,
        BaseNetworkInterceptor
    implements HttpInterceptor {
  ISpectHttpInterceptor({
    ISpectLogger? logger,
    ISpectHttpInterceptorSettings settings =
        const ISpectHttpInterceptorSettings(),
    RedactionService? redactor,
  })  : _settings = settings,
        _logger = logger ?? ISpectLogger(),
        _explicitRedactor = redactor {
    settings.resourceLimits?.validate();
  }

  final ISpectLogger _logger;
  final RedactionService? _explicitRedactor;

  @override
  ISpectLogger get logger => _logger;

  @override
  RedactionService get redactor =>
      ISpectRedaction.resolveService(service: _explicitRedactor);

  bool get _captureEnabled => _logger.hasActiveConsumers && settings.enabled;
  bool get _requestCaptureEnabled => _captureEnabled && settings.logRequests;
  bool get _responseCaptureEnabled => _captureEnabled && settings.logResponses;

  bool _captureResponseEnabled(bool isErrorResponse) =>
      isErrorResponse ? _captureEnabled : _responseCaptureEnabled;

  ISpectHttpInterceptorSettings get settings => _settings;
  ISpectHttpInterceptorSettings _settings;

  late final Expando<String> _requestIds = Expando<String>('ispect_rid');
  late final Expando<Stopwatch> _stopwatches = Expando<Stopwatch>('ispect_sw');

  @override
  bool get enableRedaction => settings.enableRedaction;

  @override
  DiagnosticCaptureMode get captureMode => settings.captureMode;

  @override
  DiagnosticResourceLimits get resourceLimits =>
      settings.resourceLimits ?? _logger.options.resourceLimits;

  ISpectTraceConfig get _traceConfig => ISpectTraceConfig(
        redact: false,
        resourceLimits: resourceLimits,
      );

  @override
  BaseNetworkInterceptorSettings get configurableSettings => _settings;

  @override
  void applyConfigurableSettings(BaseNetworkInterceptorSettings updated) {
    final typed = updated as ISpectHttpInterceptorSettings;
    typed.resourceLimits?.validate();
    _settings = typed;
  }

  @override
  FutureOr<bool> shouldInterceptRequest({required BaseRequest request}) =>
      _captureEnabled;

  @override
  FutureOr<bool> shouldInterceptResponse({required BaseResponse response}) =>
      _captureEnabled;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    guardDiagnostics(
      _logger,
      () => _captureRequest(request),
      what: 'http request capture',
    );
    return request;
  }

  void _captureRequest(BaseRequest request) {
    if (!_captureEnabled) return;

    final logRequest =
        settings.logRequests && settings.shouldProcessRequest(request);
    if (!_captureEnabled) return;

    final requestId = generateTraceId();
    _requestIds[request] = requestId;
    _stopwatches[request] = Stopwatch()..start();

    if (!logRequest || !_requestCaptureEnabled) return;

    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final operation = redactDiagnosticText(
      request.method,
      useRedaction: redactionActive,
    );
    if (!_requestCaptureEnabled) return;

    final (:url, path: _) = redactUrlAndPath(
      request.url,
      useRedaction: redactionActive,
    );
    if (!_requestCaptureEnabled) return;

    final requestDataJson = HttpRequestData(
      request,
      resourceLimits: resourceLimits,
    ).toJson(
      includeData: settings.printRequestData,
      includeHeaders: settings.printRequestHeaders,
      redactionActive: redactionActive,
      captureMode: settings.captureMode,
    );
    if (!_requestCaptureEnabled) return;
    if (redactionActive) {
      HttpRequestData.redact(
        requestDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_requestCaptureEnabled) return;
    _logger.httpRequest(
      source: 'http',
      operation: operation,
      target: url,
      correlationId: requestId,
      config: _traceConfig,
      meta: {
        NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.requestData: requestDataJson,
        NetworkLogRenderer.renderHintsKey: {
          NetworkLogRenderer.hintPrintBody: settings.printRequestData,
          NetworkLogRenderer.hintPrintHeaders: settings.printRequestHeaders,
        },
      },
    );
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    guardDiagnostics(
      _logger,
      () => _captureResponse(response),
      what: 'http response capture',
    );
    return response;
  }

  void _captureResponse(BaseResponse response) {
    if (!_captureEnabled) return;

    final isErrorResponse =
        response.statusCode >= 400 && response.statusCode < 600;

    if (!isErrorResponse &&
        (!settings.logResponses || !settings.shouldProcessResponse(response))) {
      return;
    }
    if (isErrorResponse && !settings.shouldProcessError(response)) {
      return;
    }
    if (!_captureResponseEnabled(isErrorResponse)) return;

    final request = response.request;
    final requestId = request != null ? _requestIds[request] : null;
    final sw = request != null ? _stopwatches[request] : null;
    sw?.stop();

    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final method = request?.method ?? 'UNKNOWN';
    final operation = redactDiagnosticText(
      method,
      useRedaction: redactionActive,
    );
    if (!_captureResponseEnabled(isErrorResponse)) return;

    final requestUrl = request?.url;
    final (:url, path: _) = requestUrl != null
        ? redactUrlAndPath(requestUrl, useRedaction: redactionActive)
        : (url: '', path: '');
    if (!_captureResponseEnabled(isErrorResponse)) return;

    final includeResponseData =
        isErrorResponse ? settings.printErrorData : settings.printResponseData;
    final includeResponseHeaders = isErrorResponse
        ? settings.printErrorHeaders
        : settings.printResponseHeaders;
    final includeResponseMessage = isErrorResponse
        ? settings.printErrorMessage
        : settings.printResponseMessage;
    final responseData = HttpResponseData(
      baseResponse: response,
      requestData: HttpRequestData(
        request,
        resourceLimits: resourceLimits,
      ),
      response: response is Response ? response : null,
      multipartRequest: request is MultipartRequest ? request : null,
    );

    final responseDataJson = responseData.toJson(
      includeData: includeResponseData,
      includeHeaders: includeResponseHeaders,
      includeMessage: includeResponseMessage,
      includeRequestData: settings.printRequestData,
      includeRequestHeaders: settings.printRequestHeaders,
      redactionActive: redactionActive,
      captureMode: settings.captureMode,
    );
    if (!_captureResponseEnabled(isErrorResponse)) return;
    if (redactionActive) {
      HttpResponseData.redact(
        responseDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_captureResponseEnabled(isErrorResponse)) return;
    final baseMeta = <String, Object?>{
      if (requestId != null) NetworkJsonKeys.requestId: requestId,
      NetworkJsonKeys.statusCode: response.statusCode,
      NetworkJsonKeys.responseData: responseDataJson,
    };

    if (!_captureResponseEnabled(isErrorResponse)) return;
    if (isErrorResponse) {
      _logger.httpError(
        source: 'http',
        operation: operation,
        target: url,
        correlationId: requestId,
        duration: sw?.elapsed,
        config: _traceConfig,
        meta: {
          ...baseMeta,
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintBody: settings.printErrorData,
            NetworkLogRenderer.hintPrintHeaders: settings.printErrorHeaders,
            NetworkLogRenderer.hintPrintMessage: settings.printErrorMessage,
          },
        },
      );
    } else {
      _logger.httpResponse(
        source: 'http',
        operation: operation,
        target: url,
        correlationId: requestId,
        duration: sw?.elapsed,
        config: _traceConfig,
        meta: {
          ...baseMeta,
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintBody: settings.printResponseData,
            NetworkLogRenderer.hintPrintHeaders: settings.printResponseHeaders,
            NetworkLogRenderer.hintPrintMessage: settings.printResponseMessage,
          },
        },
      );
    }
  }
}
