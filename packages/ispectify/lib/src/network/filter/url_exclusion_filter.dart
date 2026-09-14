import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/network/filter/network_filter.dart';
import 'package:ispectify/src/network/network_uri_snapshot.dart';

/// Suppresses logging for URLs matching any of [excludedPatterns].
///
/// Works with any event type [T] by extracting the URL via [urlExtractor].
/// Returns `false` (suppress) when the URL matches at least one pattern.
class UrlExclusionFilter<T> extends NetworkFilter<T> {
  /// Creates a compatibility filter for a URI-only boundary.
  ///
  /// Balanced capture preserves the historical functional behavior through a
  /// guarded [Uri.toString] call. Strict capture never invokes the formatter
  /// and fails closed when patterns are configured. Prefer
  /// [UrlExclusionFilter.trustedText] when the caller already owns URL text.
  const UrlExclusionFilter({
    required this.excludedPatterns,
    required this.urlExtractor,
    this.captureMode = DiagnosticCaptureMode.balanced,
  }) : trustedUrlExtractor = null;

  /// Creates a functional URL filter from caller-owned immutable URL text.
  const UrlExclusionFilter.trustedText({
    required this.excludedPatterns,
    required String Function(T) urlExtractor,
  })  : urlExtractor = null,
        captureMode = DiagnosticCaptureMode.strict,
        trustedUrlExtractor = urlExtractor;

  /// Patterns to match against the full URL string.
  ///
  /// Accepts [String] (exact substring) or [RegExp] instances.
  final List<Pattern> excludedPatterns;

  /// Extracts an arbitrary [Uri] from the event value.
  final Uri Function(T)? urlExtractor;

  /// Capture policy used by the URI compatibility constructor.
  final DiagnosticCaptureMode captureMode;

  /// Extracts URL text whose provenance is controlled by the caller.
  final String Function(T)? trustedUrlExtractor;

  @override
  bool apply(T value) {
    if (excludedPatterns.isEmpty) return true;
    try {
      final trustedExtractor = trustedUrlExtractor;
      final snapshot = trustedExtractor != null
          ? NetworkUriSnapshot.fromTrustedText(trustedExtractor(value))
          : NetworkUriSnapshot.fromUri(
              urlExtractor!(value),
              captureMode: captureMode,
            );
      if (!snapshot.isTrusted) return false;
      return !excludedPatterns.any(
        (pattern) => pattern.allMatches(snapshot.url).isNotEmpty,
      );
    } on Object {
      return false;
    }
  }
}
