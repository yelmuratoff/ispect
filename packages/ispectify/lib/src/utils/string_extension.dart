/// Default truncation limit for strings across the package.
const int kDefaultStringTruncateLimit = 10000;

/// Truncates [value] to [maxLength], avoiding surrogate pair splits.
///
/// Appends `...` if the string was truncated.
String truncateString(String value, {int maxLength = kDefaultStringTruncateLimit}) {
  if (value.length <= maxLength) return value;
  var end = maxLength;
  // Avoid splitting a surrogate pair at the truncation boundary.
  if (end > 0 &&
      value.codeUnitAt(end - 1) >= 0xD800 &&
      value.codeUnitAt(end - 1) <= 0xDBFF) {
    end--;
  }
  return '${value.substring(0, end)}...';
}

/// An extension on nullable [String] providing truncation.
extension ISpectStringExtension on String? {
  /// Truncates the string to [maxLength] characters.
  ///
  /// Returns `null` if the original string is `null`.
  /// Appends `...` if the string was truncated.
  String? truncate({int maxLength = kDefaultStringTruncateLimit}) {
    final original = this;
    if (original == null) return null;
    return truncateString(original, maxLength: maxLength);
  }
}
