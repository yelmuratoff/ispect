import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';
import 'package:ispectify_dio/src/models/_models.dart';
import 'package:ispectify_dio/src/settings.dart';

/// `Dio` http client logger on [ISpectify] base
///
/// `logger` field is current [ISpectify] instance.
/// Provide your instance if your application used `ISpectify` as default logger
/// Common ISpectify instance will be used by default
class ISpectDioInterceptor extends Interceptor {
  ISpectDioInterceptor({
    ISpectify? logger,
    this.settings = const ISpectDioInterceptorSettings(),
    this.addonId,
    RedactionService? redactor,
  }) {
    _logger = logger ?? ISpectify();
    _redactor = redactor ?? RedactionService();
  }

  late final ISpectify _logger;
  late final RedactionService _redactor;

  /// `ISpectDioInterceptor` settings and customization
  ISpectDioInterceptorSettings settings;

  /// ISpectify addon functionality
  /// addon id for create a lot of addons
  final String? addonId;

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
    if (redactor != null) _redactor = redactor;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    super.onRequest(options, handler);
    if (!_shouldProcessRequest(options)) return;

    final useRedaction = settings.enableRedaction;
    final message = options.uri.toString();

    final redactedHeaders = _redactHeaders(options.headers, useRedaction);
    final redactedBody = _redactBody(options.data, useRedaction);

    final httpLog = DioRequestLog(
      message,
      method: options.method,
      url: options.uri.toString(),
      path: options.uri.path,
      headers: redactedHeaders,
      body: redactedBody,
      settings: settings,
      requestData: DioRequestData(options),
      redactor: useRedaction ? _redactor : null,
    );
    _logger.logCustom(httpLog);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    if (!_shouldProcessResponse(response)) return;

    final useRedaction = settings.enableRedaction;
    final message = response.requestOptions.uri.toString();

    // Request data processing
    final requestBody = _processRequestData(
      response.requestOptions.data,
      useRedaction,
    );

    // Response data processing
    final responseBody = _redactBody(response.data, useRedaction);

    final httpLog = DioResponseLog(
      message,
      settings: settings,
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      path: response.requestOptions.uri.path,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestHeaders: _redactHeaders(
        response.requestOptions.headers,
        useRedaction,
      ),
      headers: _redactHeaders(response.headers.map, useRedaction),
      requestBody: requestBody,
      responseBody: responseBody,
      responseData: DioResponseData(
        response: response,
        requestData: DioRequestData(response.requestOptions),
      ),
      redactor: useRedaction ? _redactor : null,
    );
    _logger.logCustom(httpLog);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    if (!_shouldProcessError(err)) return;

    final useRedaction = settings.enableRedaction;
    final message = err.requestOptions.uri.toString();

    final data = _processErrorData(err.response?.data, useRedaction);
    final requestData = DioRequestData(err.requestOptions);

    final httpErrorLog = DioErrorLog(
      message,
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      path: err.requestOptions.uri.path,
      statusCode: err.response?.statusCode,
      statusMessage: err.response?.statusMessage,
      requestHeaders: _redactHeaders(
        err.requestOptions.headers.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
        useRedaction,
      ).map((key, value) => MapEntry(key, value?.toString())),
      headers: err.response == null
          ? null
          : _redactHeaders(
              err.response!.headers.map.map(
                (key, value) => MapEntry(key, value.toString()),
              ),
              useRedaction,
            ).map((key, value) => MapEntry(key, value?.toString() ?? '')),
      body: data,
      settings: settings,
      errorData: DioErrorData(
        exception: err,
        requestData: requestData,
        responseData: DioResponseData(
          response: err.response,
          requestData: requestData,
        ),
      ),
      redactor: useRedaction ? _redactor : null,
    );
    _logger.logCustom(httpErrorLog);
  }

  bool _shouldProcessRequest(RequestOptions options) {
    if (!settings.enabled) return false;
    return settings.requestFilter?.call(options) ?? true;
  }

  bool _shouldProcessResponse(Response<dynamic> response) {
    if (!settings.enabled) return false;
    return settings.responseFilter?.call(response) ?? true;
  }

  bool _shouldProcessError(DioException err) {
    if (!settings.enabled) return false;
    return settings.errorFilter?.call(err) ?? true;
  }

  Map<String, dynamic> _redactHeaders(
    Map<String, dynamic> headers,
    bool useRedaction,
  ) =>
      useRedaction ? _redactor.redactHeaders(headers) : headers;

  Object? _redactBody(Object? data, bool useRedaction) {
    if (data is FormData) {
      return _extractFormData(data, useRedaction);
    }
    return useRedaction ? _redactor.redact(data) : data;
  }

  Map<String, dynamic>? _processRequestData(
    Object? data,
    bool useRedaction,
  ) {
    if (data is FormData) {
      return _extractFormData(data, useRedaction);
    }
    final redacted = useRedaction ? _redactor.redact(data) : data;
    return redacted is Map<String, dynamic> ? redacted : {'data': redacted};
  }

  Map<String, dynamic> _processErrorData(
    Object? data,
    bool useRedaction,
  ) {
    if (data is Map<String, dynamic>) {
      final redacted = useRedaction ? _redactor.redact(data) : data;
      return (redacted as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    return {
      'data': useRedaction ? _redactor.redact(data) : data,
    };
  }

  /// Extracts FormData fields and files into a structured format for logging
  Map<String, dynamic> _extractFormData(FormData formData, bool useRedaction) {
    final rawFields = <String, Object?>{};
    for (final entry in formData.fields) {
      final existing = rawFields[entry.key];
      if (existing == null) {
        rawFields[entry.key] = entry.value;
      } else if (existing is List) {
        existing.add(entry.value);
      } else {
        rawFields[entry.key] = [existing, entry.value];
      }
    }

    final rawFiles = formData.files
        .map(
          (e) => {
            'key': e.key,
            'filename': e.value.filename,
            'contentType': e.value.contentType,
            'length': e.value.length,
            'headers': e.value.headers,
          },
        )
        .toList();

    final redFields = useRedaction
        ? (_redactor.redact(rawFields)! as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : rawFields;

    final redFiles = useRedaction
        ? (_redactor.redact(rawFiles)! as List).cast<Map<String, Object?>>()
        : rawFiles.cast<Map<String, Object?>>();

    return {
      'fields': redFields,
      'files': redFiles,
    };
  }
}
