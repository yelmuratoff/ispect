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
        BaseNetworkInterceptor {
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

  bool get _captureEnabled => _logger.hasActiveConsumers && settings.enabled;
  bool get _requestCaptureEnabled => _captureEnabled && settings.logRequests;
  bool get _responseCaptureEnabled => _captureEnabled && settings.logResponses;

  ISpectDioInterceptorSettings get settings => _settings;
  ISpectDioInterceptorSettings _settings;

  final String? addonId;

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
    final typed = updated as ISpectDioInterceptorSettings;
    typed.resourceLimits?.validate();
    _settings = typed;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!_captureEnabled) {
      super.onRequest(options, handler);
      return;
    }

    final logRequest =
        settings.logRequests && settings.shouldProcessRequest(options);
    if (!_captureEnabled) {
      super.onRequest(options, handler);
      return;
    }

    final requestId = generateTraceId();
    // RequestOptions copies carry extra, unlike Expando state.
    options.extra[NetworkJsonKeys.ispectRequestId] = requestId;
    options.extra[NetworkJsonKeys.ispectRequestStartedAt] =
        DateTime.now().microsecondsSinceEpoch;

    if (!logRequest || !_requestCaptureEnabled) {
      super.onRequest(options, handler);
      return;
    }

    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final operation = redactDiagnosticText(
      options.method,
      useRedaction: redactionActive,
    );
    if (!_requestCaptureEnabled) {
      super.onRequest(options, handler);
      return;
    }

    final requestData = DioRequestData(
      options,
      resourceLimits: resourceLimits,
    );
    final uriSnapshot = requestData.uriSnapshot;
    final url = uriSnapshot.isTrusted
        ? redactUrl(uriSnapshot.url, useRedaction: redactionActive)
        : uriSnapshot.url;
    if (!_requestCaptureEnabled) {
      super.onRequest(options, handler);
      return;
    }

    final requestDataJson = requestData.toJson(
      includeData: settings.printRequestData,
      includeHeaders: settings.printRequestHeaders,
      redactionActive: redactionActive,
      captureMode: settings.captureMode,
    );
    if (!_requestCaptureEnabled) {
      super.onRequest(options, handler);
      return;
    }
    if (redactionActive) {
      DioRequestData.redact(
        requestDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_requestCaptureEnabled) {
      super.onRequest(options, handler);
      return;
    }
    _logger.httpRequest(
      source: 'dio',
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

    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    if (!_responseCaptureEnabled) return;
    if (!settings.shouldProcessResponse(response)) return;
    if (!_responseCaptureEnabled) return;

    final requestOptions = response.requestOptions;
    final requestId = _requestIdOf(requestOptions);
    final duration = _elapsedSince(requestOptions);

    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final operation = redactDiagnosticText(
      requestOptions.method,
      useRedaction: redactionActive,
    );
    if (!_responseCaptureEnabled) return;

    final requestData = DioRequestData(
      requestOptions,
      resourceLimits: resourceLimits,
    );
    final uriSnapshot = requestData.uriSnapshot;
    final url = uriSnapshot.isTrusted
        ? redactUrl(uriSnapshot.url, useRedaction: redactionActive)
        : uriSnapshot.url;
    if (!_responseCaptureEnabled) return;

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
      config: _traceConfig,
      meta: {
        if (requestId != null) NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.statusCode: response.statusCode,
        NetworkJsonKeys.responseData: responseDataJson,
        NetworkLogRenderer.renderHintsKey: {
          NetworkLogRenderer.hintPrintBody: settings.printResponseData,
          NetworkLogRenderer.hintPrintHeaders: settings.printResponseHeaders,
          NetworkLogRenderer.hintPrintMessage: settings.printResponseMessage,
        },
      },
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    if (!_captureEnabled || !settings.shouldProcessError(err)) {
      return;
    }
    if (!_captureEnabled) return;

    final requestOptions = err.requestOptions;
    final requestId = _requestIdOf(requestOptions);
    final duration = _elapsedSince(requestOptions);

    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final operation = redactDiagnosticText(
      requestOptions.method,
      useRedaction: redactionActive,
    );
    if (!_captureEnabled) return;

    final requestData = DioRequestData(
      requestOptions,
      resourceLimits: resourceLimits,
    );
    final uriSnapshot = requestData.uriSnapshot;
    final url = uriSnapshot.isTrusted
        ? redactUrl(uriSnapshot.url, useRedaction: redactionActive)
        : uriSnapshot.url;
    if (!_captureEnabled) return;

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
    if (!_captureEnabled) return;
    if (redactionActive) {
      DioErrorData.redact(
        errorDataJson,
        redactor,
        resourceLimits: resourceLimits,
      );
    }

    if (!_captureEnabled) return;
    Object? logError;
    StackTrace? logStackTrace;
    if (settings.printErrorMessage) {
      if (redactionActive) {
        logError = NetworkMapRedactor.redactFreeTextValue(
          err,
          redactor,
          resourceLimits: resourceLimits,
        );
        if (!_captureEnabled) return;
        final redactedStackTrace = NetworkMapRedactor.redactFreeTextValue(
          err.stackTrace,
          redactor,
          resourceLimits: resourceLimits,
        );
        if (!_captureEnabled) return;
        logStackTrace = StackTrace.fromString(redactedStackTrace);
      } else {
        logError = err;
        logStackTrace = err.stackTrace;
      }
    }

    if (!_captureEnabled) return;
    _logger.httpError(
      source: 'dio',
      operation: operation,
      target: url,
      error: logError,
      errorStackTrace: logStackTrace,
      correlationId: requestId,
      duration: duration,
      config: _traceConfig,
      meta: {
        if (requestId != null) NetworkJsonKeys.requestId: requestId,
        NetworkJsonKeys.statusCode: err.response?.statusCode,
        NetworkJsonKeys.errorData: errorDataJson,
        NetworkLogRenderer.renderHintsKey: {
          NetworkLogRenderer.hintPrintBody: settings.printErrorData,
          NetworkLogRenderer.hintPrintHeaders: settings.printErrorHeaders,
          NetworkLogRenderer.hintPrintMessage: settings.printErrorMessage,
        },
      },
    );
  }

  String? _requestIdOf(RequestOptions options) {
    final id = options.extra[NetworkJsonKeys.ispectRequestId];
    return id is String ? id : null;
  }

  Duration? _elapsedSince(RequestOptions options) {
    final startedAt = options.extra[NetworkJsonKeys.ispectRequestStartedAt];
    if (startedAt is! int) return null;
    final elapsedUs = DateTime.now().microsecondsSinceEpoch - startedAt;
    // Negative if the wall clock stepped back between start and completion.
    return elapsedUs >= 0 ? Duration(microseconds: elapsedUs) : null;
  }
}
