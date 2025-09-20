import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

class HttpRequestData {
  HttpRequestData(this.requestOptions);

  final BaseRequest? requestOptions;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    bool printRequestHeaders = true,
  }) {
    final map = <String, dynamic>{
      'url': requestOptions?.url,
      'method': requestOptions?.method,
      'content-length': requestOptions?.contentLength,
      'persistent-connection': requestOptions?.persistentConnection,
      'follow-redirects': requestOptions?.followRedirects,
      'max-redirects': requestOptions?.maxRedirects,
      if (printRequestHeaders) 'headers': requestOptions?.headers,
      'finalized': requestOptions?.finalized,
    };

    if (redactor == null) return map;

    final hdrs = printRequestHeaders ? requestOptions?.headers : null;
    if (hdrs != null) {
      final red = redactor.redactHeaders(
        hdrs,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      map['headers'] = red.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }

    return map;
  }
}
