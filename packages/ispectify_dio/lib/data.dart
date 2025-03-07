import 'package:dio/dio.dart';

class DioRequestData {
  DioRequestData(this.requestOptions);

  final RequestOptions requestOptions;

  Map<String, dynamic> get toJson => {
        'path': requestOptions.path,
        'base-url': requestOptions.baseUrl,
        'uri': requestOptions.uri,
        'method': requestOptions.method,
        'data': requestOptions.data,
        'headers': requestOptions.headers,
        'query-parameters': requestOptions.queryParameters,
        'extra': requestOptions.extra,
        'preserve-header-case': requestOptions.preserveHeaderCase,
        'response-type': requestOptions.responseType,
        'content-type': requestOptions.contentType,
        'receive-data-when-status-error':
            requestOptions.receiveDataWhenStatusError,
        'follow-redirects': requestOptions.followRedirects,
        'max-redirects': requestOptions.maxRedirects,
        'persistent-connection': requestOptions.persistentConnection,
        'list-format': requestOptions.listFormat,
        'cancel-token': requestOptions.cancelToken,
        'send-timeout': requestOptions.sendTimeout,
        'receive-timeout': requestOptions.receiveTimeout,
        'connect-timeout': requestOptions.connectTimeout,
      };
}

class DioResponseData {
  DioResponseData({
    required this.response,
    required this.requestData,
  });

  final Response<dynamic>? response;

  final DioRequestData requestData;

  Map<String, dynamic> get toJson => {
        'request-options': requestData.toJson,
        'real-uri': response?.realUri,
        'data': response?.data,
        'status-code': response?.statusCode,
        'status-message': response?.statusMessage,
        'extra': response?.extra,
        'is-redirect': response?.isRedirect,
        'redirects': response?.redirects
            .map(
              (e) => {
                'location': e.location,
                'status-code': e.statusCode,
                'methid': e.method,
              },
            )
            .toList(),
        'headers': response?.headers.map,
      };
}

class DioErrorData {
  DioErrorData({
    required this.exception,
    required this.requestData,
    required this.responseData,
  });

  final DioException? exception;
  final DioRequestData requestData;
  final DioResponseData responseData;

  Map<String, dynamic> get toJson => {
        'type': exception?.type,
        'error': exception?.error,
        'stack-trace': exception?.stackTrace,
        'message': exception?.message,
        'request-options': requestData.toJson,
        'response': responseData.toJson,
      };
}
