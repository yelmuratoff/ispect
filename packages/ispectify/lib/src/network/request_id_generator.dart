/// Generates lightweight, unique request IDs for correlating
/// network request/response/error logs within a session.
///
/// Format: `net-{sessionHex}-{counter}`
/// - Session prefix: 6-char hex from microsecond timestamp at creation
/// - Counter: monotonically incrementing integer
///
/// Thread-safe in Dart's single-threaded event loop.
/// No external dependencies.
class RequestIdGenerator {
  /// Creates a generator with a unique session prefix.
  RequestIdGenerator()
      : _sessionPrefix = DateTime.now()
            .microsecondsSinceEpoch
            .toRadixString(16)
            .padLeft(6, '0')
            .substring(0, 6);

  final String _sessionPrefix;
  int _counter = 0;

  /// Generates the next unique request ID.
  String next() => 'net-$_sessionPrefix-${++_counter}';
}
