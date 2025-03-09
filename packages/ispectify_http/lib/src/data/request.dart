import 'package:http_interceptor/http_interceptor.dart';

class HttpRequestData {
  HttpRequestData(this.requestOptions);

  final BaseRequest? requestOptions;

  Map<String, dynamic> get toJson => {
        'url': requestOptions?.url,
        'method': requestOptions?.method,
        'content-length': requestOptions?.contentLength,
        'persistent-connection': requestOptions?.persistentConnection,
        'follow-redirects': requestOptions?.followRedirects,
        'max-redirects': requestOptions?.maxRedirects,
        'headers': requestOptions?.headers,
        'finalized': requestOptions?.finalized,
      };
}
