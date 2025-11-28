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
    this.settings = const ISpectDioInterceptorSettings(),
    this.addonId,
    RedactionService? redactor,
  }) {
    initializeInterceptor(logger: logger, redactor: redactor);
  }

  /// `ISpectDioInterceptor` settings and customization
  ISpectDioInterceptorSettings settings;

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
    settings = settings.copyWith(
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
    if (!_shouldProcessRequest(options)) return;

    final useRedaction = settings.enableRedaction;
    logger.logData(
      _buildRequestLog(
        options: options,
        useRedaction: useRedaction,
      ),
    );
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    if (!_shouldProcessResponse(response)) return;

    final useRedaction = settings.enableRedaction;
    logger.logData(
      _buildResponseLog(
        response: response,
        useRedaction: useRedaction,
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    if (!_shouldProcessError(err)) return;

    final useRedaction = settings.enableRedaction;
    logger.logData(
      _buildErrorLog(
        error: err,
        useRedaction: useRedaction,
      ),
    );
  }

  bool _shouldProcessRequest(RequestOptions options) =>
      settings.enabled && (settings.requestFilter?.call(options) ?? true);

  bool _shouldProcessResponse(Response<dynamic> response) =>
      settings.enabled && (settings.responseFilter?.call(response) ?? true);

  bool _shouldProcessError(DioException err) =>
      settings.enabled && (settings.errorFilter?.call(err) ?? true);

  DioRequestLog _buildRequestLog({
    required RequestOptions options,
    required bool useRedaction,
  }) =>
      DioRequestLog(
        options.uri.toString(),
        method: options.method,
        url: options.uri.toString(),
        path: options.uri.path,
        headers: payload.headersMap(
          options.headers,
          enableRedaction: useRedaction,
        ),
        body: _requestBodyPayload(options.data, useRedaction),
        settings: settings,
        requestData: DioRequestData(options),
        redactor: useRedaction ? redactor : null,
      );

  DioResponseLog _buildResponseLog({
    required Response<dynamic> response,
    required bool useRedaction,
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

    return DioResponseLog(
      requestOptions.uri.toString(),
      settings: settings,
      method: requestOptions.method,
      url: requestOptions.uri.toString(),
      path: requestOptions.uri.path,
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

    return DioErrorLog(
      requestOptions.uri.toString(),
      method: requestOptions.method,
      url: requestOptions.uri.toString(),
      path: requestOptions.uri.path,
      statusCode: response?.statusCode,
      statusMessage: response?.statusMessage,
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
  ) {
    if (data == null) return null;
    final sanitized = _responseBodyPayload(data, useRedaction);
    if (sanitized == null) return null;
    final map = payload.ensureMap(sanitized);
    return map.isEmpty ? null : map;
  }

  Object? _responseBodyPayload(Object? data, bool useRedaction) => payload.body(
        data,
        enableRedaction: useRedaction,
        normalizer: (value) =>
            value is FormData ? DioFormDataSerializer.serialize(value) : value,
      );

  Map<String, dynamic> _errorBodyPayload(
    Object? data,
    bool useRedaction,
  ) =>
      payload.ensureMap(
        _responseBodyPayload(data, useRedaction),
      );
}
