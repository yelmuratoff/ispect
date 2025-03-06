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

class HttpResponseData {
  HttpResponseData({
    required this.response,
    required this.baseResponse,
    required this.requestData,
    required this.multipartRequest,
  });

  final BaseResponse baseResponse;
  final Response? response;
  final MultipartRequest? multipartRequest;
  final HttpRequestData requestData;

  Map<String, dynamic> get toJson => {
        'url': baseResponse.request?.url,
        'status-code': baseResponse.statusCode,
        'status-message': baseResponse.reasonPhrase,
        'headers': baseResponse.headers,
        'request-data': requestData.toJson,
        'is-redirect': baseResponse.isRedirect,
        'content-length': baseResponse.contentLength,
        'persistent-connection': baseResponse.persistentConnection,
        if (response != null) 'body': response!.body,
        if (response != null) 'body-bytes': response!.bodyBytes.toString(),
        if (multipartRequest != null)
          'multipart-request': {
            'fields': multipartRequest!.fields,
            'files': multipartRequest!.files
                .map(
                  (file) => {
                    'filename': file.filename,
                    'length': file.length,
                    'contentType': file.contentType,
                    'field': file.field,
                  },
                )
                .toList(),
          },
      };
}
