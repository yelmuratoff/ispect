/// An extension on nullable `String` to provide additional utility methods.
extension ISpectStringExtension on String? {
  /// Truncates the string to a specified maximum length.
  ///
  /// If the string's length exceeds `maxLength`, it returns the first
  /// `maxLength` characters followed by an ellipsis (`...`). Otherwise, it
  /// returns the original string.
  String? truncate({
    int maxLength = 10000,
  }) {
    final original = this;
    if (original == null) return null;
    return original.length > maxLength
        ? '${original.substring(0, maxLength)}...'
        : original;
  }
}
