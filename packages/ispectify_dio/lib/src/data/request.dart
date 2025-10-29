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
    final normalizedHeaders = _stringKeyedMap(requestOptions.headers);
    final normalizedQuery = _stringKeyedMap(requestOptions.queryParameters);
    final normalizedExtra = _stringKeyedMap(requestOptions.extra);
    final normalizedData = _normalizeBody(requestOptions.data);

    final map = <String, dynamic>{
      'path': requestOptions.path,
      'base-url': requestOptions.baseUrl,
      'url': requestOptions.uri.toString(),
      'method': requestOptions.method,
      'data': normalizedData,
      'headers': normalizedHeaders,
      'query-parameters': normalizedQuery,
      'extra': normalizedExtra,
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

    if (redactor == null) {
      return map;
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
    map['extra'] = redactor.redact(
          normalizedExtra,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ) ??
        normalizedExtra;

    return map;
  }

  Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic>? source) {
    if (source == null || source.isEmpty) return <String, dynamic>{};
    return source.map((key, value) => MapEntry(key.toString(), value));
  }

  Object? _normalizeBody(Object? data) {
    if (data is FormData) {
      return DioFormDataSerializer.serialize(data);
    }
    return data;
  }
}
