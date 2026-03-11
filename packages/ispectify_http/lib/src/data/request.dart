import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

class HttpRequestData {
  HttpRequestData(this.requestOptions);

  final BaseRequest? requestOptions;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final map = <String, dynamic>{
      'url': requestOptions?.url.toString(),
      'method': requestOptions?.method,
      'data': (requestOptions is Request)
          ? (requestOptions! as Request).body
          : null,
      'content-length': requestOptions?.contentLength,
      'persistent-connection': requestOptions?.persistentConnection,
      'follow-redirects': requestOptions?.followRedirects,
      'max-redirects': requestOptions?.maxRedirects,
      'headers': requestOptions?.headers,
      'finalized': requestOptions?.finalized,
    };

    if (redactor == null) return map;

    // Redact URL query parameters
    final url = map['url'];
    if (url is String) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters.isNotEmpty) {
        final redactedParams = uri.queryParameters.map(
          (key, value) => MapEntry(key, redactor.redact(value, keyName: key)),
        );
        map['url'] = uri
            .replace(
              queryParameters: redactedParams
                  .map((k, v) => MapEntry(k, v?.toString() ?? '')),
            )
            .toString();
      }
    }

    final hdrs = requestOptions?.headers;
    if (hdrs != null) {
      final red = redactor.redactHeaders(
        hdrs,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      map['headers'] = red.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }

    if (map['data'] != null) {
      map['data'] = redactor.redact(
        map['data'],
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    return map;
  }
}
