import 'dart:math';

/// Generates lightweight, unique request IDs for correlating
/// network request/response/error logs within a session.
///
/// Format: `net-{sessionHex}-{counter}`
/// - Session prefix: 6-char hex (24 random bits) chosen at creation
/// - Counter: monotonically incrementing integer (global across all instances)
///
/// The prefix is random rather than time-derived so two sessions started close
/// together — where the counter also restarts at zero — do not collide. The
/// counter is static so IDs stay unique even when multiple interceptors
/// (e.g. Dio + http) each create their own generator.
///
/// Thread-safe in Dart's single-threaded event loop.
/// No external dependencies.
final class RequestIdGenerator {
  /// Creates a generator with a random session prefix.
  ///
  /// Pass [random] to make the prefix deterministic in tests.
  RequestIdGenerator({Random? random})
      : _sessionPrefix = (random ?? Random())
            .nextInt(0x1000000)
            .toRadixString(16)
            .padLeft(6, '0');

  final String _sessionPrefix;

  /// Global counter shared across all [RequestIdGenerator] instances
  /// to guarantee uniqueness even with identical session prefixes.
  static int _counter = 0;

  /// Generates the next unique request ID.
  String next() => 'net-$_sessionPrefix-${++_counter}';
}
