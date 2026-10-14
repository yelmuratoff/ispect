import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';
import 'package:ispectify_dio/src/settings.dart';

/// Dio HTTP client interceptor that logs requests/responses via the trace API.
class ISpectDioInterceptor extends Interceptor
    with
        NetworkLoggerMixin,
        NetworkRedactionMixin,
        NetworkConfigurationMixin,
        BaseNetworkInterceptor,
        NetworkCapturePolicyMixin {
  ISpectDioInterceptor({
    ISpectLogger? logger,
    ISpectDioInterceptorSettings settings =
        const ISpectDioInterceptorSettings(),
    this.addonId,
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

  @override
  ISpectDioInterceptorSettings get settings => _settings;
  ISpectDioInterceptorSettings _settings;

  final String? addonId;

  @override
  BaseNetworkInterceptorSettings get configurableSettings => _settings;

  @override
  void applyConfigurableSettings(BaseNetworkInterceptorSettings updated) {
    final typed = updated as ISpectDioInterceptorSettings;
    typed.resourceLimits?.validate();
    _settings = typed;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    guardDiagnostics(
      _logger,
      () => _captureRequest(options),
      what: 'Dio request capture',
    );
    super.onRequest(options, handler);
  }

  void _captureRequest(RequestOptions options) {
    if (!captureEnabled) return;

    final logRequest =
        settings.logRequests && settings.shouldProcessRequest(options);
    if (!captureEnabled) return;

    final requestId = generateTraceId();
    // RequestOptions copies carry extra, unlike Expando state.
    options.extra[NetworkJsonKeys.ispectRequestId] = requestId;
    options.extra[NetworkJsonKeys.ispectRequestStartedAt] =
        _monotonicClock.elapsedMicroseconds;

    if (!logRequest || !_requestCaptureEnabled) return;

    final prelude = _prepareRequest(
      options,
      isCapturing: () => _requestCaptureEnabled,
    );
    if (prelude == null) return;
    final (:redactionActive, :operation, :requestData, :url) = prelude;

    final requestDataJson = requestData.toJson(
      includeData: settings.printRequestData,
      includeHeaders: settings.printRequestHeaders,
      redactionActive: redactionActive,
      captureMode: settings.captureMode,
    );
    if (!_requestCaptureEnabled) return;
    if (redactionActive) {
      DioRequestData.redact(
        requestDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_requestCaptureEnabled) return;
    _logger.httpRequest(
      source: 'dio',
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
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    guardDiagnostics(
      _logger,
      () => _captureResponse(response),
      what: 'Dio response capture',
    );
  }

  void _captureResponse(Response<dynamic> response) {
    if (!_responseCaptureEnabled) return;
    if (!settings.shouldProcessResponse(response)) return;
    if (!_responseCaptureEnabled) return;

    final requestOptions = response.requestOptions;
    final requestId = _requestIdOf(requestOptions);
    final duration = _elapsedSince(requestOptions);

    final prelude = _prepareRequest(
      requestOptions,
      isCapturing: () => _responseCaptureEnabled,
    );
    if (prelude == null) return;
    final (:redactionActive, :operation, :requestData, :url) = prelude;

    final responseDataJson = DioResponseData(
      response: response,
      requestData: requestData,
    ).toJson(
      includeData: settings.printResponseData,
      includeHeaders: settings.printResponseHeaders,
      includeMessage: settings.printResponseMessage,
      includeRequestData: settings.printRequestData,
      includeRequestHeaders: settings.printRequestHeaders,
      redactionActive: redactionActive,
      captureMode: settings.captureMode,
    );
    if (!_responseCaptureEnabled) return;
    if (redactionActive) {
      DioResponseData.redact(
        responseDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_responseCaptureEnabled) return;
    _logger.httpResponse(
      source: 'dio',
      operation: operation,
      target: url,
      correlationId: requestId,
      duration: duration,
      config: capturedTraceConfig,
      meta: {
        if (requestId != null) NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.statusCode: response.statusCode,
        NetworkJsonKeys.responseData: responseDataJson,
        NetworkLogRenderer.renderHintsKey: settings.responseRenderHints,
      },
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    guardDiagnostics(
      _logger,
      () => _captureError(err),
      what: 'Dio error capture',
    );
  }

  void _captureError(DioException err) {
    if (!captureEnabled || !settings.shouldProcessError(err)) {
      return;
    }
    if (!captureEnabled) return;

    final requestOptions = err.requestOptions;
    final requestId = _requestIdOf(requestOptions);
    final duration = _elapsedSince(requestOptions);

    final prelude = _prepareRequest(
      requestOptions,
      isCapturing: () => captureEnabled,
    );
    if (prelude == null) return;
    final (:redactionActive, :operation, :requestData, :url) = prelude;

    final errorDataJson = DioErrorData(
      exception: err,
      requestData: requestData,
      responseData: DioResponseData(
        response: err.response,
        requestData: requestData,
      ),
    ).toJson(
      includeData: settings.printErrorData,
      includeHeaders: settings.printErrorHeaders,
      includeMessage: settings.printErrorMessage,
      includeRequestData: settings.printRequestData,
      includeRequestHeaders: settings.printRequestHeaders,
      redactionActive: redactionActive,
      captureMode: settings.captureMode,
    );
    if (!captureEnabled) return;
    if (redactionActive) {
      DioErrorData.redact(
        errorDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!captureEnabled) return;
    Object? logError;
    StackTrace? logStackTrace;
    if (settings.printErrorMessage) {
      if (redactionActive) {
        logError = NetworkMapRedactor.redactFreeTextValue(
          err,
          redactor,
          resourceLimits: resourceLimits,
        );
        if (!captureEnabled) return;
        final redactedStackTrace = NetworkMapRedactor.redactFreeTextValue(
          err.stackTrace,
          redactor,
          resourceLimits: resourceLimits,
        );
        if (!captureEnabled) return;
        logStackTrace = StackTrace.fromString(redactedStackTrace);
      } else {
        logError = err;
        logStackTrace = err.stackTrace;
      }
    }

    if (!captureEnabled) return;
    _logger.httpError(
      source: 'dio',
      operation: operation,
      target: url,
      error: logError,
      errorStackTrace: logStackTrace,
      correlationId: requestId,
      duration: duration,
      config: capturedTraceConfig,
      meta: {
        if (requestId != null) NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.statusCode: err.response?.statusCode,
        NetworkJsonKeys.errorData: errorDataJson,
        NetworkLogRenderer.renderHintsKey: settings.errorRenderHints,
      },
    );
  }

  _RequestPrelude? _prepareRequest(
    RequestOptions options, {
    required bool Function() isCapturing,
  }) {
    final redactionActive = settings.isRedactionActive;
    final operation = redactDiagnosticText(
      options.method,
      useRedaction: redactionActive,
    );
    if (!isCapturing()) return null;

    final requestData = DioRequestData(
      options,
      resourceLimits: resourceLimits,
    );
    final uriSnapshot = requestData.uriSnapshot;
    final url = uriSnapshot.isTrusted
        ? redactUrl(uriSnapshot.url, useRedaction: redactionActive)
        : uriSnapshot.url;
    if (!isCapturing()) return null;
    return (
      redactionActive: redactionActive,
      operation: operation,
      requestData: requestData,
      url: url,
    );
  }

  String? _requestIdOf(RequestOptions options) {
    final id = options.extra[NetworkJsonKeys.ispectRequestId];
    return id is String ? id : null;
  }

  Duration? _elapsedSince(RequestOptions options) {
    final startedAt = options.extra[NetworkJsonKeys.ispectRequestStartedAt];
    if (startedAt is! int) return null;
    return Duration(
      microseconds: _monotonicClock.elapsedMicroseconds - startedAt,
    );
  }

  static final Stopwatch _monotonicClock = Stopwatch()..start();
}

typedef _RequestPrelude = ({
  bool redactionActive,
  String operation,
  DioRequestData requestData,
  String url,
});
