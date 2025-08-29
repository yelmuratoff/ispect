import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';
import 'package:ispectify_dio/src/models/_models.dart';
import 'package:ispectify_dio/src/settings.dart';

/// `Dio` http client logger on [ISpectify] base
///
/// `logger` filed is current [ISpectify] instance.
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

  late ISpectify _logger;
  late RedactionService _redactor;

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
    if (!settings.enabled) {
      return;
    }
    final accepted = settings.requestFilter?.call(options) ?? true;
    if (!accepted) {
      return;
    }
    try {
      final message = '${options.uri}';

      // Redact headers and body safely before logging
      final useRedaction = settings.enableRedaction;
      final redactedHeaders = useRedaction
          ? _redactor.redactHeaders(options.headers)
          : options.headers;
      final Object? redactedBody;
      if (options.data is FormData) {
        redactedBody = '[form-data]';
      } else {
        redactedBody =
            useRedaction ? _redactor.redact(options.data) : options.data;
      }

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
    } catch (_) {
      //pass
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    if (!settings.enabled) {
      return;
    }
    final accepted = settings.responseFilter?.call(response) ?? true;
    if (!accepted) {
      return;
    }
    try {
      final message = '${response.requestOptions.uri}';

      //
      // <--- Request data --->
      //
      final useRedaction = settings.enableRedaction;
      Map<String, dynamic>? requestBody;
      if (response.requestOptions.data is FormData) {
        final formData = response.requestOptions.data as FormData;
        final fields = formData.fields;
        final files = formData.files
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
        requestBody = {
          'fields': fields,
          'files': files,
        };
      } else {
        final Object? reqData = response.requestOptions.data;
        final red = useRedaction ? _redactor.redact(reqData) : reqData;
        requestBody = red is Map<String, dynamic> ? red : {'data': red};
      }

      //
      // <--- Response data --->
      //
      Object? responseBody;
      if (response.data is FormData) {
        final formData = response.data as FormData;
        final fields = formData.fields;
        final files = formData.files
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
        responseBody = {
          'fields': fields,
          'files': files,
        };
      } else {
        responseBody =
            useRedaction ? _redactor.redact(response.data) : response.data;
      }

      final httpLog = DioResponseLog(
        message,
        settings: settings,
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        path: response.requestOptions.uri.path,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        requestHeaders: useRedaction
            ? _redactor
                .redactHeaders(response.requestOptions.headers)
                .map((k, v) => MapEntry(k, v?.toString()))
            : response.requestOptions.headers
                .map((k, v) => MapEntry(k, v.toString())),
        headers: useRedaction
            ? _redactor
                .redactHeaders(
                  response.headers.map
                      .map((key, value) => MapEntry(key, value.toString())),
                )
                .map((k, v) => MapEntry(k, v?.toString() ?? ''))
            : response.headers.map
                .map((key, value) => MapEntry(key, value.toString())),
        requestBody: requestBody,
        responseBody: responseBody,
        responseData: DioResponseData(
          response: response,
          requestData: DioRequestData(response.requestOptions),
        ),
        redactor: useRedaction ? _redactor : null,
      );
      _logger.logCustom(httpLog);
    } catch (_) {
      //pass
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    if (!settings.enabled) {
      return;
    }
    final accepted = settings.errorFilter?.call(err) ?? true;
    if (!accepted) {
      return;
    }
    try {
      final message = '${err.requestOptions.uri}';
      final useRedaction = settings.enableRedaction;
      Map<String, dynamic> data;
      if (err.response?.data is Map<String, dynamic>) {
        data = (useRedaction
                ? _redactor.redact(err.response?.data)
                : err.response?.data) as Map<String, dynamic>? ??
            <String, dynamic>{};
      } else {
        data = {
          'data': useRedaction
              ? _redactor.redact(err.response?.data)
              : err.response?.data,
        };
      }
      final requestData = DioRequestData(err.requestOptions);
      final httpErrorLog = DioErrorLog(
        message,
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        path: err.requestOptions.uri.path,
        statusCode: err.response?.statusCode,
        statusMessage: err.response?.statusMessage,
        requestHeaders: useRedaction
            ? _redactor
                .redactHeaders(err.requestOptions.headers)
                .map((k, v) => MapEntry(k, v?.toString()))
            : err.requestOptions.headers
                .map((k, v) => MapEntry(k, v.toString())),
        headers: err.response == null
            ? null
            : (useRedaction
                ? _redactor
                    .redactHeaders(
                      err.response!.headers.map
                          .map((key, value) => MapEntry(key, value.toString())),
                    )
                    .map((k, v) => MapEntry(k, v?.toString() ?? ''))
                : err.response!.headers.map
                    .map((key, value) => MapEntry(key, value.toString()))),
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
    } catch (_) {
      //pass
    }
  }
}
