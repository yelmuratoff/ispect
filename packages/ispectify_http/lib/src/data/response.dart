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
      'method': baseResponse.request?.method,
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
            : _tryDecodeJson(response!.body),
      if (response != null && redactor == null)
        'body-bytes': response!.bodyBytes.length.toString(),
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

    // Redact URL query parameters and userInfo credentials
    final url = map['url'];
    if (url is String) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final hasParams = uri.queryParameters.isNotEmpty;
        final hasUserInfo = uri.userInfo.isNotEmpty;
        if (hasParams || hasUserInfo) {
          final redactedParams = hasParams
              ? uri.queryParameters.map(
                  (key, value) =>
                      MapEntry(key, redactor.redact(value, keyName: key)),
                )
              : null;
          map['url'] = uri
              .replace(
                userInfo: hasUserInfo ? '[REDACTED]' : null,
                queryParameters: redactedParams
                    ?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
              )
              .toString();
        }
      }
    }

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
        );
        if (red is Map) {
          mp['fields'] = red.map((k, v) => MapEntry(k.toString(), v));
        }
      }

      // Files
      final files = mp['files'];
      if (files is List) {
        final red = redactor.redact(
          files,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        );
        if (red is List) {
          mp['files'] = red
              .whereType<Map<dynamic, dynamic>>()
              .map(Map<String, Object?>.from)
              .toList();
        }
      }

      map['multipart-request'] = mp;
    }

    return map;
  }

  static Object _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Object) return decoded;
      return body;
    } catch (_) {
      return body;
    }
  }

  /// Helper method to get redacted body content
  static Object _getRedactedBody(
    String body,
    RedactionService redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is! Object) return body;
      final redacted = redactor.redact(
        parsed,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return redacted is Object ? redacted : parsed;
    } catch (_) {
      final redacted = redactor.redact(
        body,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      return redacted is Object ? redacted : body;
    }
  }
}
