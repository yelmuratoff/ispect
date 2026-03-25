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
      NetworkJsonKeys.method: requestOptions?.method,
      NetworkJsonKeys.url: requestOptions?.url.toString(),

      // --- Payload ---
      NetworkJsonKeys.headers: requestOptions?.headers,
      NetworkJsonKeys.encoding: (requestOptions is Request)
          ? (requestOptions! as Request).encoding.name
          : null,
      NetworkJsonKeys.data: (requestOptions is Request)
          ? (requestOptions! as Request).body
          : null,
      NetworkJsonKeys.contentLength: requestOptions?.contentLength,

      // --- Behaviour ---
      NetworkJsonKeys.followRedirects: requestOptions?.followRedirects,
      NetworkJsonKeys.maxRedirects: requestOptions?.maxRedirects,
      NetworkJsonKeys.persistentConnection:
          requestOptions?.persistentConnection,

      // --- State ---
      NetworkJsonKeys.finalized: requestOptions?.finalized,
    };

    if (redactor == null) return map;

    NetworkMapRedactor.redactUrl(map, redactor);
    final redactedHeaders = NetworkMapRedactor.redactHeaders(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    if (redactedHeaders != null) {
      map[NetworkJsonKeys.headers] =
          redactedHeaders.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    NetworkMapRedactor.redactData(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    return map;
  }
}
