import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/utils/form_data_serializer.dart';

class DioRequestData {
  DioRequestData(this.requestOptions);

  final RequestOptions requestOptions;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final normalizedHeaders = NetworkPayloadSanitizer.toStringKeyMap(requestOptions.headers);
    final normalizedQuery = NetworkPayloadSanitizer.toStringKeyMap(requestOptions.queryParameters);
    final normalizedExtra = NetworkPayloadSanitizer.toStringKeyMap(requestOptions.extra);
    final normalizedData = _normalizeBody(requestOptions.data);

    final map = <String, dynamic>{
      // --- Identity: what & where ---
      'method': requestOptions.method,
      'url': requestOptions.uri.toString(),
      'base-url': requestOptions.baseUrl,
      'path': requestOptions.path,
      'query-parameters': normalizedQuery,

      // --- Payload ---
      'content-type': requestOptions.contentType,
      'headers': normalizedHeaders,
      'data': normalizedData,

      // --- Timing ---
      'connect-timeout': requestOptions.connectTimeout,
      'send-timeout': requestOptions.sendTimeout,
      'receive-timeout': requestOptions.receiveTimeout,

      // --- Behaviour ---
      'follow-redirects': requestOptions.followRedirects,
      'max-redirects': requestOptions.maxRedirects,
      'response-type': requestOptions.responseType,
      'receive-data-when-status-error':
          requestOptions.receiveDataWhenStatusError,
      'persistent-connection': requestOptions.persistentConnection,
      'preserve-header-case': requestOptions.preserveHeaderCase,
      'list-format': requestOptions.listFormat,
      'cancel-token': requestOptions.cancelToken,

      // --- Meta ---
      'extra': normalizedExtra,
    };

    if (redactor == null) {
      return map;
    }

    // Redact path and base-url which may contain credentials or sensitive
    // segments (e.g. base-url with userInfo like https://user:pass@host).
    final rawPath = map['path'];
    if (rawPath is String) {
      map['path'] = redactor.redact(rawPath, keyName: 'path') ?? rawPath;
    }
    final rawBaseUrl = map['base-url'];
    if (rawBaseUrl is String) {
      final baseUri = Uri.tryParse(rawBaseUrl);
      if (baseUri != null && baseUri.userInfo.isNotEmpty) {
        map['base-url'] = baseUri
            .replace(userInfo: userInfoRedactedPlaceholder)
            .toString();
      }
    }

    // Redact URL query parameters and userInfo credentials
    final url = map['url'];
    if (url is String) {
      map['url'] = redactor.redactUrl(url);
    }

    // Apply redaction to known sensitive sections when a redactor is provided.
    final hasDataKey = map.containsKey('data');
    final Object? rawData = hasDataKey ? map['data'] : null;

    map['data'] = hasDataKey
        ? redactor.redact(
              rawData,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ) ??
            rawData
        : null;

    map['headers'] = redactor.redactHeaders(
      normalizedHeaders,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    map['query-parameters'] = redactor.redact(
          normalizedQuery,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ) ??
        normalizedQuery;
    final redactedExtra = redactor.redact(
          normalizedExtra,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ) ??
        normalizedExtra;
    // Preserve internal request ID from redaction.
    if (redactedExtra is Map<String, dynamic> &&
        normalizedExtra.containsKey('_ispect_rid')) {
      redactedExtra['_ispect_rid'] = normalizedExtra['_ispect_rid'];
    }
    map['extra'] = redactedExtra;

    return map;
  }

  Object? _normalizeBody(Object? data) {
    if (data is FormData) {
      return DioFormDataSerializer.serialize(data);
    }
    return data;
  }
}
