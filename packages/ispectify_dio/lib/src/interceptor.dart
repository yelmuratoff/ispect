import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';
import 'package:ispectify_dio/src/models/_models.dart';
import 'package:ispectify_dio/src/settings.dart';
import 'package:ispectify_dio/src/utils/form_data_serializer.dart';

/// `Dio` http client logger on [ISpectLogger] base
///
/// `logger` field is current [ISpectLogger] instance.
/// Provide your instance if your application used `ISpectLogger` as default logger
/// Common ISpectLogger instance will be used by default
class ISpectDioInterceptor extends Interceptor with BaseNetworkInterceptor {
  ISpectDioInterceptor({
    ISpectLogger? logger,
    ISpectDioInterceptorSettings settings = const ISpectDioInterceptorSettings(),
    this.addonId,
    RedactionService? redactor,
  })  : _settings = settings,
        _logger = logger ?? ISpectLogger() {
    if (redactor != null) this.redactor = redactor;
  }

  final ISpectLogger _logger;

  @override
  ISpectLogger get logger => _logger;

  /// Internal key used to store the request ID in [RequestOptions.extra].
  static const _requestIdExtraKey = '_ispect_rid';

  final RequestIdGenerator _requestIdGenerator = RequestIdGenerator();

  /// Current settings for this interceptor.
  ///
  /// Use [configure] for partial updates. The settings object itself is
  /// immutable — updates replace the entire instance.
  ISpectDioInterceptorSettings get settings => _settings;
  ISpectDioInterceptorSettings _settings;

  /// ISpectLogger addon functionality
  /// addon id for create a lot of addons
  final String? addonId;

  @override
  bool get enableRedaction => settings.enableRedaction;

  /// Method to update `settings` of [ISpectDioInterceptor]
  void configure({
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
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
    if (!shouldProcess(enabled: settings.enabled, filter: settings.requestFilter, value: options)) {
      return;
    }

    final requestId = _requestIdGenerator.next();
    options.extra[_requestIdExtraKey] = requestId;

    safeLog(
      () => _buildRequestLog(
        options: options,
        requestId: requestId,
        useRedaction: settings.enableRedaction,
      ),
    );
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    if (!shouldProcess(enabled: settings.enabled, filter: settings.responseFilter, value: response)) {
      return;
    }

    final requestId =
        response.requestOptions.extra[_requestIdExtraKey] as String?;

    safeLog(
      () => _buildResponseLog(
        response: response,
        requestId: requestId,
        useRedaction: settings.enableRedaction,
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    if (!shouldProcess(enabled: settings.enabled, filter: settings.errorFilter, value: err)) return;

    final requestId = err.requestOptions.extra[_requestIdExtraKey] as String?;

    safeLog(
      () => _buildErrorLog(
        error: err,
        requestId: requestId,
        useRedaction: settings.enableRedaction,
      ),
    );
  }

  DioRequestLog _buildRequestLog({
    required RequestOptions options,
    required String requestId,
    required bool useRedaction,
  }) {
    final (:url, :path) = redactUrlAndPath(
      options.uri,
      useRedaction: useRedaction,
    );
    return DioRequestLog(
      url,
      method: options.method,
      url: url,
      path: path,
      requestId: requestId,
      headers: payload.headersMap(
        options.headers,
        enableRedaction: useRedaction,
      ),
      body: _requestBodyPayload(options.data, useRedaction),
      settings: settings,
      requestData: DioRequestData(options),
      redactor: useRedaction ? redactor : null,
    );
  }

  DioResponseLog _buildResponseLog({
    required Response<dynamic> response,
    required bool useRedaction,
    String? requestId,
  }) {
    final requestOptions = response.requestOptions;
    final requestHeaders = settings.printRequestHeaders
        ? payload.headersOrNull(
            requestOptions.headers,
            enableRedaction: useRedaction,
          )
        : null;

    final responseHeaders = settings.printResponseHeaders
        ? payload.headersOrNull(
            response.headers.map,
            enableRedaction: useRedaction,
          )
        : null;

    final (:url, :path) = redactUrlAndPath(
      requestOptions.uri,
      useRedaction: useRedaction,
    );
    return DioResponseLog(
      url,
      settings: settings,
      method: requestOptions.method,
      url: url,
      path: path,
      requestId: requestId,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestHeaders: requestHeaders,
      headers: responseHeaders,
      requestBody: settings.printRequestData
          ? _requestBodyPayload(requestOptions.data, useRedaction)
          : null,
      responseBody: settings.printResponseData
          ? _responseBodyPayload(response.data, useRedaction)
          : null,
      responseData: DioResponseData(
        response: response,
        requestData: DioRequestData(requestOptions),
      ),
      redactor: useRedaction ? redactor : null,
    );
  }

  DioErrorLog _buildErrorLog({
    required DioException error,
    required bool useRedaction,
    String? requestId,
  }) {
    final requestOptions = error.requestOptions;
    final response = error.response;
    final requestHeaders = payload
        .headersOrNull(
          requestOptions.headers,
          enableRedaction: useRedaction,
        )
        ?.map((key, value) => MapEntry(key, value?.toString()));

    final responseHeaders = response == null
        ? null
        : payload
            .headersOrNull(
              response.headers.map,
              enableRedaction: useRedaction,
            )
            ?.map(
              (key, value) => MapEntry(
                key,
                value == null ? '' : value.toString(),
              ),
            );

    final requestData = DioRequestData(requestOptions);

    final (:url, :path) = redactUrlAndPath(
      requestOptions.uri,
      useRedaction: useRedaction,
    );
    final statusMessage = redactErrorMessage(
      response?.statusMessage,
      useRedaction: useRedaction,
    );
    return DioErrorLog(
      url,
      method: requestOptions.method,
      url: url,
      path: path,
      requestId: requestId,
      statusCode: response?.statusCode,
      statusMessage: statusMessage,
      requestHeaders: requestHeaders,
      headers: responseHeaders,
      body: _errorBodyPayload(response?.data, useRedaction),
      settings: settings,
      errorData: DioErrorData(
        exception: error,
        requestData: requestData,
        responseData: DioResponseData(
          response: response,
          requestData: requestData,
        ),
      ),
      redactor: useRedaction ? redactor : null,
    );
  }

  Map<String, dynamic>? _requestBodyPayload(
    Object? data,
    bool useRedaction,
  ) =>
      bodyAsMap(data, useRedaction: useRedaction, normalizer: _normalizeFormData);

  Object? _responseBodyPayload(Object? data, bool useRedaction) => payload.body(
        data,
        enableRedaction: useRedaction,
        normalizer: _normalizeFormData,
      );

  Map<String, dynamic> _errorBodyPayload(
    Object? data,
    bool useRedaction,
  ) =>
      payload.ensureMap(
        _responseBodyPayload(data, useRedaction),
      );

  static Object? _normalizeFormData(Object? value) =>
      value is FormData ? DioFormDataSerializer.serialize(value) : value;

}
