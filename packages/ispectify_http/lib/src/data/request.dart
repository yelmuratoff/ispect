import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

class HttpRequestData {
  HttpRequestData(this.requestOptions);

  final BaseRequest? requestOptions;

  Map<String, dynamic> toJson() => <String, dynamic>{
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

  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
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
  }
}
