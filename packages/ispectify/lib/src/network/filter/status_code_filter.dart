import 'package:ispectify/src/network/filter/network_filter.dart';

/// Passes only events whose HTTP status code satisfies [predicate].
///
/// Works with any event type [T] by extracting the status code via
/// [statusCodeExtractor].
class StatusCodeFilter<T> extends NetworkFilter<T> {
  const StatusCodeFilter({
    required this.predicate,
    required this.statusCodeExtractor,
  });

  /// Returns `true` for status codes that should be logged.
  final bool Function(int) predicate;

  /// Extracts the HTTP status code from the event value.
  final int Function(T) statusCodeExtractor;

  @override
  bool apply(T value) => predicate(statusCodeExtractor(value));
}
