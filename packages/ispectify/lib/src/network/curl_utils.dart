import 'package:ispectify/ispectify.dart';

/// Utility class for generating cURL commands from HTTP request data.
class CurlUtils {
  /// Generates a cURL command string from the provided request data.
  ///
  /// - [data]: A map containing request details such as 'uri', 'method', 'headers', 'data'.
  /// Returns `null` if the data is insufficient to generate a valid cURL command.
  static String? generateCurl(Map<String, dynamic>? data) {
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

    final headers = data['headers'] as Map<String, dynamic>?;
    if (headers != null) {
      headers.forEach((key, value) {
        if (value != null) {
          buffer.write(' -H ${_shellEscape('$key: $value')}');
        }
      });
    }

    final body = data['data'];
    if (body != null) {
      final bodyString =
          body is String ? body : JsonTruncatorService.pretty(body);
      buffer.write(' -d ${_shellEscape(bodyString)}');
    }

    return buffer.toString();
  }

  static String _shellEscape(String value) {
    final escaped = value.replaceAll("'", r"'\''");
    return "'$escaped'";
  }
}
