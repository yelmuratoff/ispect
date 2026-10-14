import 'dart:async';
import 'dart:typed_data';

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
        BaseNetworkInterceptor,
        NetworkCapturePolicyMixin
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

  bool get _requestCaptureEnabled => captureEnabled && settings.logRequests;
  bool get _responseCaptureEnabled => captureEnabled && settings.logResponses;

  bool _captureResponseEnabled(bool isErrorResponse) =>
      isErrorResponse ? captureEnabled : _responseCaptureEnabled;

  @override
  ISpectHttpInterceptorSettings get settings => _settings;
  ISpectHttpInterceptorSettings _settings;

  late final Expando<String> _requestIds = Expando<String>('ispect_rid');
  late final Expando<Stopwatch> _stopwatches = Expando<Stopwatch>('ispect_sw');

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
      captureEnabled;

  @override
  FutureOr<bool> shouldInterceptResponse({required BaseResponse response}) =>
      captureEnabled;

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
    if (!captureEnabled) return;

    final logRequest =
        settings.logRequests && settings.shouldProcessRequest(request);
    if (!captureEnabled) return;

    final requestId = generateTraceId();
    _requestIds[request] = requestId;
    _stopwatches[request] = Stopwatch()..start();

    if (!logRequest || !_requestCaptureEnabled) return;

    final redactionActive = settings.isRedactionActive;
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
      config: capturedTraceConfig,
      meta: {
        NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.requestData: requestDataJson,
        NetworkLogRenderer.renderHintsKey: settings.requestRenderHints,
      },
    );
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (_shouldTeeBody(response) && response is StreamedResponse) {
      final request = response.request;
      if (request != null) _stopwatches[request]?.stop();
      return _teeBody(response);
    }
    guardDiagnostics(
      _logger,
      () => _captureResponse(response),
      what: 'http response capture',
    );
    return response;
  }

  // http_interceptor 3 hands response interceptors the unread StreamedResponse.
  bool _shouldTeeBody(BaseResponse response) {
    final contentLength = response.contentLength;
    return response is StreamedResponse &&
        contentLength != null &&
        contentLength <= resourceLimits.maxNetworkBodyBytes &&
        _bodyCaptureEnabled(response);
  }

  StreamedResponse _teeBody(StreamedResponse response) {
    final budget = resourceLimits.maxNetworkBodyBytes;
    final received = BytesBuilder();
    var overflowed = false;
    var settled = false;

    void settle({required bool complete}) {
      if (settled) return;
      settled = true;
      final bytes = received.takeBytes();
      guardDiagnostics(
        _logger,
        () => _captureResponse(
          response,
          body: complete && !overflowed
              ? Response.bytes(
                  bytes,
                  response.statusCode,
                  request: response.request,
                  headers: response.headers,
                  isRedirect: response.isRedirect,
                  persistentConnection: response.persistentConnection,
                  reasonPhrase: response.reasonPhrase,
                )
              : null,
        ),
        what: 'http response capture',
      );
    }

    late final StreamSubscription<List<int>> subscription;
    final controller = StreamController<List<int>>(sync: true);
    Timer.run(() {
      if (!controller.hasListener) settle(complete: false);
    });
    controller
      ..onListen = () {
        subscription = response.stream.listen(
          (chunk) {
            if (!settled && !overflowed) {
              if (received.length + chunk.length > budget) {
                overflowed = true;
                received.clear();
              } else {
                received.add(chunk);
              }
            }
            controller.add(chunk);
          },
          onError: (Object error, StackTrace stackTrace) {
            settle(complete: false);
            controller.addError(error, stackTrace);
            unawaited(controller.close());
          },
          onDone: () {
            settle(complete: true);
            unawaited(controller.close());
          },
          cancelOnError: true,
        );
      }
      ..onPause = (() => subscription.pause())
      ..onResume = (() => subscription.resume())
      ..onCancel = () {
        settle(complete: false);
        return subscription.cancel();
      };

    return _TeedStreamedResponse(response, controller.stream);
  }

  static bool _isErrorStatus(int statusCode) =>
      statusCode >= _minErrorStatusCode && statusCode <= _maxErrorStatusCode;

  bool _bodyCaptureEnabled(BaseResponse response) {
    final isErrorResponse = _isErrorStatus(response.statusCode);
    if (!_captureResponseEnabled(isErrorResponse)) return false;
    return isErrorResponse
        ? settings.printErrorData
        : settings.logResponses && settings.printResponseData;
  }

  void _captureResponse(BaseResponse response, {Response? body}) {
    if (!captureEnabled) return;

    final isErrorResponse = _isErrorStatus(response.statusCode);

    if (!isErrorResponse &&
        (!settings.logResponses || !settings.shouldProcessResponse(response))) {
      return;
    }
    if (isErrorResponse && !settings.shouldProcessError(response)) {
      return;
    }
    if (!_captureResponseEnabled(isErrorResponse)) return;

    final prepared = _prepareResponse(
      response,
      body: response is Response ? response : body,
      isErrorResponse: isErrorResponse,
    );
    if (prepared == null) return;

    if (!_captureResponseEnabled(isErrorResponse)) return;
    if (isErrorResponse) {
      _logErrorResponse(prepared);
    } else {
      _logSuccessResponse(prepared);
    }
  }

  _PreparedResponse? _prepareResponse(
    BaseResponse response, {
    required Response? body,
    required bool isErrorResponse,
  }) {
    final request = response.request;
    final requestId = request != null ? _requestIds[request] : null;
    final sw = request != null ? _stopwatches[request] : null;
    sw?.stop();

    final redactionActive = settings.isRedactionActive;
    final method = request?.method ?? _unknownMethod;
    final operation = redactDiagnosticText(
      method,
      useRedaction: redactionActive,
    );
    if (!_captureResponseEnabled(isErrorResponse)) return null;

    final requestUrl = request?.url;
    final (:url, path: _) = requestUrl != null
        ? redactUrlAndPath(requestUrl, useRedaction: redactionActive)
        : (url: '', path: '');
    if (!_captureResponseEnabled(isErrorResponse)) return null;

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
      response: body,
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
    final contentLength = response.contentLength;
    if (body == null &&
        includeResponseData &&
        contentLength != null &&
        contentLength > resourceLimits.maxNetworkBodyBytes) {
      responseDataJson[NetworkJsonKeys.body] = LogExportOutput.truncatedMarker;
      responseDataJson[NetworkJsonKeys.bodyBytes] = contentLength.toString();
    }
    if (!_captureResponseEnabled(isErrorResponse)) return null;
    if (redactionActive) {
      HttpResponseData.redact(
        responseDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_captureResponseEnabled(isErrorResponse)) return null;
    return (
      operation: operation,
      target: url,
      requestId: requestId,
      duration: sw?.elapsed,
      meta: <String, Object?>{
        if (requestId != null) NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.statusCode: response.statusCode,
        if (isErrorResponse)
          NetworkJsonKeys.errorData: responseDataJson
        else
          NetworkJsonKeys.responseData: responseDataJson,
      },
    );
  }

  void _logErrorResponse(_PreparedResponse prepared) {
    _logger.httpError(
      source: 'http',
      operation: prepared.operation,
      target: prepared.target,
      correlationId: prepared.requestId,
      duration: prepared.duration,
      config: capturedTraceConfig,
      meta: {
        ...prepared.meta,
        NetworkLogRenderer.renderHintsKey: settings.errorRenderHints,
      },
    );
  }

  void _logSuccessResponse(_PreparedResponse prepared) {
    _logger.httpResponse(
      source: 'http',
      operation: prepared.operation,
      target: prepared.target,
      correlationId: prepared.requestId,
      duration: prepared.duration,
      config: capturedTraceConfig,
      meta: {
        ...prepared.meta,
        NetworkLogRenderer.renderHintsKey: settings.responseRenderHints,
      },
    );
  }
}

const _minErrorStatusCode = 400;
const _maxErrorStatusCode = 599;
const _unknownMethod = 'UNKNOWN';

final class _TeedStreamedResponse extends StreamedResponse
    implements BaseResponseWithUrl {
  _TeedStreamedResponse(StreamedResponse source, Stream<List<int>> stream)
      : url = source is BaseResponseWithUrl
            ? (source as BaseResponseWithUrl).url
            : source.request?.url ?? Uri(),
        super(
          stream,
          source.statusCode,
          contentLength: source.contentLength,
          request: source.request,
          headers: source.headers,
          isRedirect: source.isRedirect,
          persistentConnection: source.persistentConnection,
          reasonPhrase: source.reasonPhrase,
        );

  @override
  final Uri url;
}

typedef _PreparedResponse = ({
  String operation,
  String target,
  String? requestId,
  Duration? duration,
  Map<String, Object?> meta,
});
