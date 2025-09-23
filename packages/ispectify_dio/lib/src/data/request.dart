import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';

class DioRequestData {
  DioRequestData(this.requestOptions);

  final RequestOptions requestOptions;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final map = <String, dynamic>{
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

    if (redactor == null) {
      return map;
    }

    // Apply redaction to known sensitive sections when a redactor is provided.
    final hasDataKey = map.containsKey('data');
    final Object? rawData = hasDataKey ? map['data'] : null;
    final rawHeaders = (map['headers'] as Map).cast<String, dynamic>();

    final rawQuery = (map['query-parameters'] as Map).cast<String, dynamic>();
    final rawExtra = (map['extra'] as Map).cast<String, dynamic>();

    if (hasDataKey) {
      map['data'] = redactor.redact(
        rawData,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    map['headers'] = redactor.redactHeaders(
      rawHeaders,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    map['query-parameters'] = redactor.redact(
      rawQuery,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    map['extra'] = redactor.redact(
      rawExtra,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    return map;
  }
}
