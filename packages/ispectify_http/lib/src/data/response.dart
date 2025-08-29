import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/request.dart';

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

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final map = <String, dynamic>{
      'url': baseResponse.request?.url,
      'status-code': baseResponse.statusCode,
      'status-message': baseResponse.reasonPhrase,
      'request-data': redactor == null
          ? requestData.toJson()
          : requestData.toJson(
              redactor: redactor,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
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
      'headers': baseResponse.headers,
    };

    if (redactor == null) return map;

    // Redact headers (Map<String, String>) while preserving shape
    map['headers'] = redactor
        .redactHeaders(
          baseResponse.headers,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        )
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));

    // Redact string body when present
    if (response != null && map['body'] is String) {
      map['body'] = redactor.redact(
        map['body'],
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    return map;
  }
}
