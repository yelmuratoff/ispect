import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';
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

    _logger.trace(
      category: networkCategory,
      source: 'dio',
      operation: options.method,
      target: url,
      logKey: ISpectLogType.httpRequest.key,
      correlationId: requestId,
      success: true,
      config: useRedaction ? null : _noRedactConfig,
      meta: {
        'requestId': requestId,
        'requestData': DioRequestData(options).toJson(
          redactor: useRedaction ? redactor : null,
        ),
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

    _logger.trace(
      category: networkCategory,
      source: 'dio',
      operation: requestOptions.method,
      target: url,
      logKey: ISpectLogType.httpResponse.key,
      correlationId: requestId,
      success: true,
      duration: sw?.elapsed,
      config: useRedaction ? null : _noRedactConfig,
      meta: {
        if (requestId != null) 'requestId': requestId,
        'statusCode': response.statusCode,
        'responseData': DioResponseData(
          response: response,
          requestData: requestData,
        ).toJson(redactor: useRedaction ? redactor : null),
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

    _logger.trace(
      category: networkCategory,
      source: 'dio',
      operation: requestOptions.method,
      target: url,
      logKey: ISpectLogType.httpError.key,
      correlationId: requestId,
      success: false,
      error: err,
      errorStackTrace: err.stackTrace,
      duration: sw?.elapsed,
      config: useRedaction ? null : _noRedactConfig,
      meta: {
        if (requestId != null) 'requestId': requestId,
        'statusCode': err.response?.statusCode,
        'errorData': DioErrorData(
          exception: err,
          requestData: requestData,
          responseData: DioResponseData(
            response: err.response,
            requestData: requestData,
          ),
        ).toJson(redactor: useRedaction ? redactor : null),
      },
    );
  }
}
