/// Standard HTTP request methods, which never carry caller data.
abstract final class HttpMethods {
  static const Set<String> standard = {
    'GET',
    'HEAD',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
    'TRACE',
    'CONNECT',
  };

  /// Whether [method] is one of the [standard] verbs, matched exactly.
  static bool isStandard(String method) => standard.contains(method);
}
