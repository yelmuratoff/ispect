import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';
import 'package:ispectify_dio/src/message_builder.dart';
import 'package:ispectify_dio/src/settings.dart';

/// Dio HTTP client interceptor that logs requests/responses via the trace API.
class ISpectDioInterceptor extends Interceptor with BaseNetworkInterceptor {
  ISpectDioInterceptor({
    ISpectLogger? logger,
    ISpectDioInterceptorSettings settings =
        const ISpectDioInterceptorSettings(),
    this.addonId,
    RedactionService? redactor,
  })  : _settings = settings,
        _logger = logger ?? ISpectLogger() {
    if (redactor != null) this.redactor = redactor;
  }

  final ISpectLogger _logger;

  @override
  ISpectLogger get logger => _logger;

  static const _requestIdExtraKey = NetworkJsonKeys.ispectRequestId;
  static const _stopwatchExtraKey = '_ispect_sw';

  ISpectDioInterceptorSettings get settings => _settings;
  ISpectDioInterceptorSettings _settings;

  final String? addonId;

  @override
  bool get enableRedaction => settings.enableRedaction;

  /// Trace config that respects interceptor's redaction setting.
  /// When enableRedaction is false, Layer 2 (trace pipeline) won't redact meta.
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
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    super.onRequest(options, handler);
    if (!shouldProcess(
      enabled: settings.enabled,
      filter: settings.requestFilter,
      value: options,
    )) {
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

    final requestDataJson = DioRequestData(options).toJson(
      redactor: useRedaction ? redactor : null,
    );

    _logger.httpRequest(
      source: 'dio',
      operation: options.method,
      target: url,
      correlationId: requestId,
      config: useRedaction ? null : _noRedactConfig,
      consoleMessage: buildDioConsoleMessage(
        source: 'dio',
        operation: options.method,
        target: url,
        printBody: settings.printRequestData,
        printHeaders: settings.printRequestHeaders,
        body: requestDataJson[NetworkJsonKeys.data],
        headers: _asStringMap(requestDataJson[NetworkJsonKeys.headers]),
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
    if (!shouldProcess(
      enabled: settings.enabled,
      filter: settings.responseFilter,
      value: response,
    )) {
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
    ).toJson(redactor: useRedaction ? redactor : null);

    _logger.httpResponse(
      source: 'dio',
      operation: requestOptions.method,
      target: url,
      correlationId: requestId,
      duration: sw?.elapsed,
      config: useRedaction ? null : _noRedactConfig,
      consoleMessage: buildDioConsoleMessage(
        source: 'dio',
        operation: requestOptions.method,
        target: url,
        duration: sw?.elapsed,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        body: responseDataJson[NetworkJsonKeys.data],
        headers: _asStringMap(responseDataJson[NetworkJsonKeys.headers]),
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
    if (!shouldProcess(
      enabled: settings.enabled,
      filter: settings.errorFilter,
      value: err,
    )) {
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
    ).toJson(redactor: useRedaction ? redactor : null);

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
      config: useRedaction ? null : _noRedactConfig,
      consoleMessage: buildDioConsoleMessage(
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
        headers: _asStringMap(errorResponseJson?[NetworkJsonKeys.headers]),
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

  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
