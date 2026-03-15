import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

class HttpRequestData {
  HttpRequestData(this.requestOptions);

  final BaseRequest? requestOptions;

  /// Converts this request data to a JSON-compatible map.
  ///
  /// When [redactor] is null, raw data (including URL query parameters,
  /// headers with auth tokens, and body content) is returned without
  /// any sanitization. Callers opting out of redaction accept
  /// responsibility for handling sensitive data appropriately.
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
