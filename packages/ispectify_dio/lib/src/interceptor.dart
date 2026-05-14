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
        _redactor = redactor ?? RedactionService();

  final ISpectLogger _logger;
  final RedactionService _redactor;

  @override
  ISpectLogger get logger => _logger;

  @override
  RedactionService get redactor => _redactor;

  ISpectDioInterceptorSettings get settings => _settings;
  ISpectDioInterceptorSettings _settings;

  final Expando<String> _requestIds = Expando<String>('ispect_rid');
  final Expando<Stopwatch> _stopwatches = Expando<Stopwatch>('ispect_sw');

  final String? addonId;

  @override
  bool get enableRedaction => settings.enableRedaction;

  @override
  BaseNetworkInterceptorSettings get configurableSettings => _settings;

  @override
  void applyConfigurableSettings(BaseNetworkInterceptorSettings updated) {
    _settings = updated as ISpectDioInterceptorSettings;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    super.onRequest(options, handler);
    if (!settings.enabled || !settings.shouldProcessRequest(options)) {
      return;
    }

    final requestId = generateTraceId();
    _requestIds[options] = requestId;
    _stopwatches[options] = Stopwatch()..start();

    final useRedaction = settings.enableRedaction;
    final (:url, path: _) = redactUrlAndPath(
      options.uri,
      useRedaction: useRedaction,
    );

    final requestDataJson = DioRequestData(options).toJson();
    if (useRedaction) DioRequestData.redact(requestDataJson, redactor);

    _logger.httpRequest(
      source: 'dio',
      operation: options.method,
      target: url,
      correlationId: requestId,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
      meta: {
        'request-id': requestId,
        'request-data': requestDataJson,
        NetworkLogRenderer.renderHintsKey: {
          NetworkLogRenderer.hintPrintBody: settings.printRequestData,
          NetworkLogRenderer.hintPrintHeaders: settings.printRequestHeaders,
        },
      },
    );
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    if (!settings.enabled || !settings.shouldProcessResponse(response)) {
      return;
    }

    final requestOptions = response.requestOptions;
    final requestId = _requestIds[requestOptions];
    final sw = _stopwatches[requestOptions];
    sw?.stop();

    final useRedaction = settings.enableRedaction;
    final (:url, path: _) = redactUrlAndPath(
      requestOptions.uri,
      useRedaction: useRedaction,
    );
    final requestData = DioRequestData(requestOptions);
    final responseDataJson = DioResponseData(
      response: response,
      requestData: requestData,
    ).toJson();
    if (useRedaction) DioResponseData.redact(responseDataJson, redactor);

    _logger.httpResponse(
      source: 'dio',
      operation: requestOptions.method,
      target: url,
      correlationId: requestId,
      duration: sw?.elapsed,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
      meta: {
        if (requestId != null) 'request-id': requestId,
        'status-code': response.statusCode,
        'response-data': responseDataJson,
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
    if (!settings.enabled || !settings.shouldProcessError(err)) {
      return;
    }

    final requestOptions = err.requestOptions;
    final requestId = _requestIds[requestOptions];
    final sw = _stopwatches[requestOptions];
    sw?.stop();

    final useRedaction = settings.enableRedaction;
    final (:url, path: _) = redactUrlAndPath(
      requestOptions.uri,
      useRedaction: useRedaction,
    );
    final requestData = DioRequestData(requestOptions);
    final errorDataJson = DioErrorData(
      exception: err,
      requestData: requestData,
      responseData: DioResponseData(
        response: err.response,
        requestData: requestData,
      ),
    ).toJson();
    if (useRedaction) DioErrorData.redact(errorDataJson, redactor);

    _logger.httpError(
      source: 'dio',
      operation: requestOptions.method,
      target: url,
      error: err,
      errorStackTrace: err.stackTrace,
      correlationId: requestId,
      duration: sw?.elapsed,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
      meta: {
        if (requestId != null) 'request-id': requestId,
        'status-code': err.response?.statusCode,
        'error-data': errorDataJson,
        NetworkLogRenderer.renderHintsKey: {
          NetworkLogRenderer.hintPrintBody: settings.printErrorData,
          NetworkLogRenderer.hintPrintHeaders: settings.printErrorHeaders,
          NetworkLogRenderer.hintPrintMessage: settings.printErrorMessage,
        },
      },
    );
  }
}
