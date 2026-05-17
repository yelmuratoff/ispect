/// Utilities for normalizing and fingerprinting SQL statements.
///
/// Used to group structurally identical queries regardless of literal values.
final class DbSqlDigest {
  const DbSqlDigest._();

  static final RegExp _singleQuoteRe = RegExp("'[^']*'");
  static final RegExp _doubleQuoteRe = RegExp(r'\"[^\"]*\"');
  static final RegExp _digitRe = RegExp(r'\b\d+\b');
  static final RegExp _whitespaceRe = RegExp(r'\s+');

  /// Maximum length of the normalized SQL prefix in [compute] output.
  static const _maxDigestPrefixLen = 80;

  /// DJB2 hash initial seed.
  static const _djb2Seed = 5381;

  /// Bitmask for DJB2 hash to keep it within 32-bit range.
  static const _hashMask = 0xffffffff;

  /// Bitmask to ensure positive hash value.
  static const _positiveHashMask = 0x7fffffff;

  /// Normalizes a SQL [statement] by replacing string literals and digits with
  /// `?`, then appends a DJB2 hash for grouping structurally identical queries.
  ///
  /// Returns `null` when [statement] is `null` or empty.
  static String? compute(String? statement) {
    if (statement == null || statement.isEmpty) return null;
    var s = statement.toLowerCase();
    s = s.replaceAll(_singleQuoteRe, '?');
    s = s.replaceAll(_doubleQuoteRe, '?');
    s = s.replaceAll(_digitRe, '?');
    s = s.replaceAll(_whitespaceRe, ' ').trim();

    var hash = _djb2Seed;
    for (var i = 0; i < s.length; i++) {
      hash = (((hash << 5) + hash) ^ s.codeUnitAt(i)) & _hashMask;
    }
    final hex = (hash & _positiveHashMask).toRadixString(16);
    final prefixEnd =
        s.length > _maxDigestPrefixLen ? _maxDigestPrefixLen : s.length;
    return '${s.substring(0, prefixEnd)}|$hex';
  }
}
