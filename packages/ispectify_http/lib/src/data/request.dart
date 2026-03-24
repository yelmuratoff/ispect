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
      // --- Identity: what & where ---
      'method': requestOptions?.method,
      'url': requestOptions?.url.toString(),

      // --- Payload ---
      'headers': requestOptions?.headers,
      'encoding': (requestOptions is Request)
          ? (requestOptions! as Request).encoding.name
          : null,
      'data': (requestOptions is Request)
          ? (requestOptions! as Request).body
          : null,
      'content-length': requestOptions?.contentLength,

      // --- Behaviour ---
      'follow-redirects': requestOptions?.followRedirects,
      'max-redirects': requestOptions?.maxRedirects,
      'persistent-connection': requestOptions?.persistentConnection,

      // --- State ---
      'finalized': requestOptions?.finalized,
    };

    if (redactor == null) return map;

    // Redact URL query parameters and userInfo credentials
    final url = map['url'];
    if (url is String) {
      map['url'] = redactor.redactUrl(url);
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
