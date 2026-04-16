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

  static const _requestIdExtraKey = NetworkJsonKeys.ispectRequestId;
  static const _stopwatchExtraKey = '_ispect_sw';

  ISpectDioInterceptorSettings get settings => _settings;
  ISpectDioInterceptorSettings _settings;

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
    options.extra[_requestIdExtraKey] = requestId;
    options.extra[_stopwatchExtraKey] = Stopwatch()..start();

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
      consoleMessage: buildNetworkConsoleMessage(
        source: 'dio',
        operation: options.method,
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
    final requestId = requestOptions.extra[_requestIdExtraKey] as String?;
    final sw = requestOptions.extra[_stopwatchExtraKey] as Stopwatch?;
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
      consoleMessage: buildNetworkConsoleMessage(
        source: 'dio',
        operation: requestOptions.method,
        target: url,
        duration: sw?.elapsed,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        body: responseDataJson[NetworkJsonKeys.data],
        headers: BaseNetworkInterceptor.asStringMap(
          responseDataJson[NetworkJsonKeys.headers],
        ),
        printStatusCode: true,
        printStatusMessage: settings.printResponseMessage,
        printBody: settings.printResponseData,
        printHeaders: settings.printResponseHeaders,
      ),
      meta: {
        if (requestId != null) 'request-id': requestId,
        'status-code': response.statusCode,
        'response-data': responseDataJson,
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
    final requestId = requestOptions.extra[_requestIdExtraKey] as String?;
    final sw = requestOptions.extra[_stopwatchExtraKey] as Stopwatch?;
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

    final errorResponseJson =
        errorDataJson[NetworkJsonKeys.response] as Map<String, dynamic>?;

    _logger.httpError(
      source: 'dio',
      operation: requestOptions.method,
      target: url,
      error: err,
      errorStackTrace: err.stackTrace,
      correlationId: requestId,
      duration: sw?.elapsed,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
      consoleMessage: buildNetworkConsoleMessage(
        source: 'dio',
        operation: requestOptions.method,
        target: url,
        duration: sw?.elapsed,
        success: false,
        statusCode: err.response?.statusCode,
        statusMessage: err.response?.statusMessage,
        errorMessage: settings.printErrorMessage
            ? errorDataJson[NetworkJsonKeys.message] as String?
            : null,
        body: errorResponseJson?[NetworkJsonKeys.data],
        headers: BaseNetworkInterceptor.asStringMap(
          errorResponseJson?[NetworkJsonKeys.headers],
        ),
        printStatusCode: true,
        printStatusMessage: settings.printErrorMessage,
        printErrorMessage: settings.printErrorMessage,
        printBody: settings.printErrorData,
        printHeaders: settings.printErrorHeaders,
      ),
      meta: {
        if (requestId != null) 'request-id': requestId,
        'status-code': err.response?.statusCode,
        'error-data': errorDataJson,
      },
    );
  }
}
