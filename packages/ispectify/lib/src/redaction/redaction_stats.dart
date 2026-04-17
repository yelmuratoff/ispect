/// Lightweight counters tracking what a single redaction traversal redacted.
///
/// Useful for debugging ("why is my field hidden?") and observability.
/// Each traversal owns one [RedactionStats] that is populated during the walk
/// and exposed via [RedactionResult] or [HeaderRedactionResult].
class RedactionStats {
  int _keyBased = 0;
  int _patternBased = 0;
  int _depthLimited = 0;

  /// Fields redacted because their key matched a sensitive/fully-masked key.
  int get keyBased => _keyBased;

  /// Fields redacted because their value matched a content pattern
  /// (JWT, base64, binary, token prefix, etc.).
  int get patternBased => _patternBased;

  /// Nodes replaced with placeholder because max depth was reached.
  int get depthLimited => _depthLimited;

  /// Total number of redacted fields.
  int get total => _keyBased + _patternBased + _depthLimited;

  /// Whether any redaction was applied.
  bool get hasRedactions => total > 0;

  void incrementKeyBased() => _keyBased++;

  void incrementPatternBased() => _patternBased++;

  void incrementDepthLimited() => _depthLimited++;

  @override
  String toString() =>
      'RedactionStats(keyBased: $_keyBased, patternBased: $_patternBased, '
      'depthLimited: $_depthLimited, total: $total)';
}
