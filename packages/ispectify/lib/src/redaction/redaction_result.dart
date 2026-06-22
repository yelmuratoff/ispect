import 'package:ispectify/src/redaction/redaction_stats.dart';

/// The outcome of a redaction operation: the redacted data and statistics
/// about what was redacted.
final class RedactionResult {
  const RedactionResult({
    required this.data,
    required this.stats,
  });

  /// The redacted data (Map, List, scalar, or null).
  final Object? data;

  /// Statistics about what was redacted during this operation.
  final RedactionStats stats;
}

/// The outcome of a header redaction operation.
final class HeaderRedactionResult {
  const HeaderRedactionResult({
    required this.headers,
    required this.stats,
  });

  /// The redacted headers.
  final Map<String, Object?> headers;

  /// Statistics about what was redacted during this operation.
  final RedactionStats stats;
}
