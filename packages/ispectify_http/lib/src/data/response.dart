import 'dart:convert';

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
      'url': baseResponse.request?.url.toString(),
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
      if (response != null)
        'body': redactor != null
            ? _getRedactedBody(
                response!.body,
                redactor,
                ignoredValues,
                ignoredKeys,
              )
            : response!.body,
      if (response != null && redactor == null)
        'body-bytes': response!.bodyBytes.toString(),
      if (multipartRequest != null)
        'multipart-request': {
          'fields': multipartRequest!.fields,
          'files': multipartRequest!.files
              .map(
                (file) => {
                  'filename': file.filename,
                  'length': file.length,
                  'contentType': file.contentType.toString(),
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

    // Redact multipart request fields/files and mask filenames
    if (multipartRequest != null && map['multipart-request'] is Map) {
      final mp = Map<String, dynamic>.from(
        map['multipart-request'] as Map,
      );

      // Fields
      final fields = mp['fields'];
      if (fields is Map) {
        final red = redactor.redact(
          fields,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        )! as Map;
        mp['fields'] = red.map((k, v) => MapEntry(k.toString(), v));
      }

      // Files
      final files = mp['files'];
      if (files is List) {
        final red = redactor.redact(
          files,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        )! as List;
        mp['files'] =
            red.map((e) => Map<String, Object?>.from(e as Map)).toList();
      }

      map['multipart-request'] = mp;
    }

    return map;
  }

  /// Helper method to get redacted body content
  static String _getRedactedBody(
    String body,
    RedactionService redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    try {
      // Try to parse as JSON and redact the parsed object
      final parsed = jsonDecode(body);
      final redacted = redactor.redact(
        parsed,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      // Return the redacted object as JSON string
      return jsonEncode(redacted);
    } catch (_) {
      // If not valid JSON, redact as string
      final redacted = redactor.redact(
        body,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return redacted?.toString() ?? body;
    }
  }
}
