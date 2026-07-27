import 'package:ispectify/src/network/filter/network_filter.dart';
import 'package:ispectify/src/network/network_uri_snapshot.dart';

/// Suppresses logging for URLs matching any of [excludedPatterns].
///
/// Works with any event type [T] by extracting the URL via [urlExtractor].
/// Returns `false` (suppress) when the URL matches at least one pattern.
class UrlExclusionFilter<T> extends NetworkFilter<T> {
  /// Creates a compatibility filter for a URI-only boundary.
  ///
  /// An arbitrary [Uri] cannot be inspected safely because the interface is
  /// implementable. When patterns are configured this constructor therefore
  /// fails closed and suppresses the event. Prefer [UrlExclusionFilter.trustedText]
  /// when the caller owns URL text independently of a [Uri].
  const UrlExclusionFilter({
    required this.excludedPatterns,
    required this.urlExtractor,
  }) : trustedUrlExtractor = null;

  /// Creates a functional URL filter from caller-owned immutable URL text.
  const UrlExclusionFilter.trustedText({
    required this.excludedPatterns,
    required String Function(T) urlExtractor,
  })  : urlExtractor = null,
        trustedUrlExtractor = urlExtractor;

  /// Patterns to match against the full URL string.
  ///
  /// Accepts [String] (exact substring) or [RegExp] instances.
  final List<Pattern> excludedPatterns;

  /// Extracts an arbitrary [Uri] from the event value.
  ///
  /// Retained for source compatibility. Its result is never inspected.
  final Uri Function(T)? urlExtractor;

  /// Extracts URL text whose provenance is controlled by the caller.
  final String Function(T)? trustedUrlExtractor;

  @override
  bool apply(T value) {
    if (excludedPatterns.isEmpty) return true;
    final extractor = trustedUrlExtractor;
    if (extractor == null) return false;
    try {
      final snapshot = NetworkUriSnapshot.fromTrustedText(extractor(value));
      if (!snapshot.isTrusted) return false;
      return !excludedPatterns.any(
        (pattern) => pattern.allMatches(snapshot.url).isNotEmpty,
      );
    } on Object {
      return false;
    }
  }
}
