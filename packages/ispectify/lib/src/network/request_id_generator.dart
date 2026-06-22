/// Generates lightweight, unique request IDs for correlating
/// network request/response/error logs within a session.
///
/// Format: `net-{sessionHex}-{counter}`
/// - Session prefix: 6-char hex from microsecond timestamp at creation
/// - Counter: monotonically incrementing integer (global across all instances)
///
/// The counter is static so that IDs are unique even when multiple
/// interceptors (e.g. Dio + http) each create their own generator
/// within the same microsecond.
///
/// Thread-safe in Dart's single-threaded event loop.
/// No external dependencies.
final class RequestIdGenerator {
  /// Creates a generator with a unique session prefix.
  RequestIdGenerator()
      : _sessionPrefix = DateTime.now()
            .microsecondsSinceEpoch
            .toRadixString(16)
            .padLeft(6, '0')
            .substring(0, 6);

  final String _sessionPrefix;

  /// Global counter shared across all [RequestIdGenerator] instances
  /// to guarantee uniqueness even with identical session prefixes.
  static int _counter = 0;

  /// Generates the next unique request ID.
  String next() => 'net-$_sessionPrefix-${++_counter}';
}
