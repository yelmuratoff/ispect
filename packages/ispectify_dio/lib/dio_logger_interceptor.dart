import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/data.dart';
import 'package:ispectify_dio/dio_logger_settings.dart';
import 'package:ispectify_dio/dio_logs.dart';

/// [Dio] http client logger on [ISpectify] base
///
/// [iSpectify] filed is current [ISpectify] instance.
/// Provide your instance if your application used [ISpectify] as default logger
/// Common ISpectify instance will be used by default
class ISpectifyDioLogger extends Interceptor {
  ISpectifyDioLogger({
    ISpectify? iSpectify,
    this.settings = const ISpectifyDioLoggerSettings(),
    this.addonId,
  }) {
    _iSpectify = iSpectify ?? ISpectify();
  }

  late ISpectify _iSpectify;

  /// [ISpectifyDioLogger] settings and customization
  ISpectifyDioLoggerSettings settings;

  /// ISpectify addon functionality
  /// addon id for create a lot of addons
  final String? addonId;

  /// Method to update [settings] of [ISpectifyDioLogger]
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

      final httpLog = DioRequestLog(
        message,
        method: options.method,
        url: options.uri.toString(),
        path: options.uri.path,
        headers: options.headers,
        body: options.data,
        settings: settings,
        requestData: DioRequestData(options),
      );
      _iSpectify.logCustom(httpLog);
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
        requestBody = response.requestOptions.data as Map<String, dynamic>?;
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
        responseBody = response.data;
      }

      final httpLog = DioResponseLog(
        message,
        settings: settings,
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        path: response.requestOptions.uri.path,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        requestHeaders: response.requestOptions.headers,
        headers: response.headers.map
            .map((key, value) => MapEntry(key, value.toString())),
        requestBody: requestBody,
        responseBody: responseBody,
        responseData: DioResponseData(
          response: response,
          requestData: DioRequestData(response.requestOptions),
        ),
      );
      _iSpectify.logCustom(httpLog);
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
      Map<String, dynamic> data;
      if (err.response?.data is Map<String, dynamic>) {
        data = err.response?.data as Map<String, dynamic>;
      } else {
        data = {'data': err.response?.data};
      }
      final requestData = DioRequestData(err.requestOptions);
      final httpErrorLog = DioErrorLog(
        message,
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        path: err.requestOptions.uri.path,
        statusCode: err.response?.statusCode,
        statusMessage: err.response?.statusMessage,
        requestHeaders: err.requestOptions.headers,
        headers: err.response?.headers.map
            .map((key, value) => MapEntry(key, value.toString())),
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
      );
      _iSpectify.logCustom(httpErrorLog);
    } catch (_) {
      //pass
    }
  }
}
