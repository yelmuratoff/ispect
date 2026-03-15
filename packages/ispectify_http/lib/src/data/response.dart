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
    this.preDecodedBody,
  });

  final BaseResponse baseResponse;
  final Response? response;
  final MultipartRequest? multipartRequest;
  final HttpRequestData requestData;

  /// Optional pre-decoded body to avoid redundant JSON parsing.
  /// When provided, [toJson] will use this value instead of re-decoding
  /// [response.body].
  final Object? preDecodedBody;

  /// Converts this response data to a JSON-compatible map.
  ///
  /// When [redactor] is null, raw data (including URL query parameters,
  /// headers with auth tokens, body content, and multipart filenames)
  /// is returned without any sanitization. Callers opting out of
  /// redaction accept responsibility for handling sensitive data.
  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final resp = response;
    final preDecoded = preDecodedBody;
    final multipart = multipartRequest;
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
      if (resp != null)
        'body': preDecoded != null
            ? (redactor != null
                ? _redactPreDecoded(
                    preDecoded,
                    redactor,
                    ignoredValues,
                    ignoredKeys,
                  )
                : preDecoded)
            : (redactor != null
                ? _getRedactedBody(
                    resp.body,
                    redactor,
                    ignoredValues,
                    ignoredKeys,
                  )
                : _tryDecodeJson(resp.body)),
      if (resp != null && redactor == null)
        'body-bytes': resp.bodyBytes.length.toString(),
      if (multipart != null)
        'multipart-request': {
          'fields': multipart.fields,
          'files': multipart.files
              .map(
                (file) => {
                  'filename': redactor != null
                      ? redactor.redact(
                          file.filename,
                          keyName: 'filename',
                          ignoredValues: ignoredValues,
                          ignoredKeys: ignoredKeys,
                        )
                      : file.filename,
                  'length': file.length,
                  'contentType': file.contentType.toString(),
                  'field': redactor != null
                      ? redactor.redact(
                          file.field,
                          keyName: 'field',
                          ignoredValues: ignoredValues,
                          ignoredKeys: ignoredKeys,
                        )
                      : file.field,
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
    final multipartData = map['multipart-request'];
    if (multipart != null && multipartData is Map) {
      final mp = Map<String, dynamic>.from(multipartData);

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

  /// Redacts an already-decoded body value without re-parsing JSON.
  static Object _redactPreDecoded(
    Object body,
    RedactionService redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    final redacted = redactor.redact(
      body,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    return redacted is Object ? redacted : body;
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
