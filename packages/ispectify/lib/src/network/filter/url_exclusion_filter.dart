import 'package:ispectify/src/network/filter/network_filter.dart';

/// Suppresses logging for URLs matching any of [excludedPatterns].
///
/// Works with any event type [T] by extracting the URL via [urlExtractor].
/// Returns `false` (suppress) when the URL matches at least one pattern.
class UrlExclusionFilter<T> extends NetworkFilter<T> {
  const UrlExclusionFilter({
    required this.excludedPatterns,
    required this.urlExtractor,
  });

  /// Patterns to match against the full URL string.
  ///
  /// Accepts [String] (exact substring) or [RegExp] instances.
  final List<Pattern> excludedPatterns;

  /// Extracts the [Uri] from the event value.
  final Uri Function(T) urlExtractor;

  @override
  bool apply(T value) {
    final url = urlExtractor(value).toString();
    return !excludedPatterns.any((p) => p.allMatches(url).isNotEmpty);
  }
}
