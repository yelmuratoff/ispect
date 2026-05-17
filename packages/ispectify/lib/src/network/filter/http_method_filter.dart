import 'package:ispectify/src/network/filter/network_filter.dart';

/// Passes only events whose HTTP method is in [allowedMethods].
///
/// Works with any event type [T] by extracting the method via
/// [methodExtractor]. Method comparison is case-sensitive — callers should
/// normalise to uppercase if needed.
class HttpMethodFilter<T> extends NetworkFilter<T> {
  const HttpMethodFilter({
    required this.allowedMethods,
    required this.methodExtractor,
  });

  /// Allowed HTTP methods (e.g. `{'GET', 'POST'}`).
  final Set<String> allowedMethods;

  /// Extracts the HTTP method string from the event value.
  final String Function(T) methodExtractor;

  @override
  bool apply(T value) => allowedMethods.contains(methodExtractor(value));
}
