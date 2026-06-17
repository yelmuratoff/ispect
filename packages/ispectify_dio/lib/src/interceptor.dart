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
    if (!settings.enabled || !settings.shouldProcessRequest(options)) {
      super.onRequest(options, handler);
      return;
    }

    final requestId = generateTraceId();
    // Park trace state in extra (not an Expando) so it survives the fresh
    // RequestOptions a downstream copyWith allocates; write it before forwarding
    // so that copy carries it.
    options.extra[NetworkJsonKeys.ispectRequestId] = requestId;
    options.extra[NetworkJsonKeys.ispectRequestStartedAt] =
        DateTime.now().microsecondsSinceEpoch;

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
    if (!settings.enabled || !settings.shouldProcessResponse(response)) {
      return;
    }

    final requestOptions = response.requestOptions;
    final requestId = _requestIdOf(requestOptions);
    final duration = _elapsedSince(requestOptions);

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
      duration: duration,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
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
    if (!settings.enabled || !settings.shouldProcessError(err)) {
      return;
    }

    final requestOptions = err.requestOptions;
    final requestId = _requestIdOf(requestOptions);
    final duration = _elapsedSince(requestOptions);

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
      duration: duration,
      config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
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
