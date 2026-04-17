import 'package:ispectify/ispectify.dart';

/// Utility class for generating cURL commands from HTTP request data.
class CurlUtils {
  /// Generates a cURL command string from the provided request data.
  ///
  /// - [data]: A map containing request details such as 'uri', 'method',
  ///   'headers', 'data'.
  /// - [redactor]: When provided, header values are passed through
  ///   [RedactionService.redactHeaders] and the body through
  ///   [RedactionService.redact] before being written to the command.
  ///
  /// **Headers and body are NOT redacted unless a [RedactionService] is
  /// provided.** Without a [redactor], values such as `Authorization`,
  /// `Cookie`, and `X-API-Key` will appear verbatim in the generated string.
  /// Always pass a [redactor] when the result is exposed to users (copy to
  /// clipboard, share sheet, bug report).
  ///
  /// Returns `null` if the data is insufficient to generate a valid cURL
  /// command.
  static String? generateCurl(
    Map<String, dynamic>? data, {
    RedactionService? redactor,
  }) {
    if (data == null ||
        (!data.containsKey('uri') && !data.containsKey('url')) ||
        !data.containsKey('method')) {
      return null;
    }

    final uri = data['uri'] as String? ?? data['url'] as String?;
    final method = data['method'] as String?;
    if (uri == null || method == null) return null;

    final buffer = StringBuffer(
      'curl -X ${_shellEscape(method)} ${_shellEscape(uri)}',
    );

    final rawHeaders = data['headers'] as Map<String, dynamic>?;
    final headers = rawHeaders == null
        ? null
        : redactor != null
            ? redactor.redactHeaders(Map<String, Object?>.from(rawHeaders))
            : rawHeaders;
    if (headers != null) {
      headers.forEach((key, value) {
        if (value != null) {
          buffer.write(' -H ${_shellEscape('$key: $value')}');
        }
      });
    }

    final rawBody = data['data'];
    final body = rawBody == null || redactor == null
        ? rawBody
        : redactor.redact(rawBody);
    if (body != null) {
      final bodyString = body is String ? body : JsonTruncator.pretty(body);
      buffer.write(' -d ${_shellEscape(bodyString)}');
    }

    return buffer.toString();
  }

  static String _shellEscape(String value) {
    final escaped = value.replaceAll("'", r"'\''");
    return "'$escaped'";
  }
}
