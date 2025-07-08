import 'package:dio/dio.dart';

class DioRequestData {
  DioRequestData(this.requestOptions);

  final RequestOptions requestOptions;

  Map<String, dynamic> get toJson => {
        'path': requestOptions.path,
        'base-url': requestOptions.baseUrl,
        'uri': requestOptions.uri.toString(),
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
