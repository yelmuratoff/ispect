/// An extension on nullable [String] to provide additional utility methods.
extension ISpectStringExtension on String? {
  /// An extension getter that truncates the string to a maximum of 10000 characters.
  ///
  /// If the string's length exceeds 10000 characters, it returns the first 10000
  /// characters followed by an ellipsis (`...`). Otherwise, it returns the
  /// original string.
  ///
  /// Example:
  /// ```dart
  /// String longText = "This is a very long text that exceeds one hundred characters. It keeps going and going.";
  /// print(longText.truncated);
  /// // Output: "This is a very long text that exceeds one hundred characters. It keeps going and go..."
  ///
  /// String shortText = "Short text.";
  /// print(shortText.truncated);
  /// // Output: "Short text."
  /// ```
  String? get truncated {
    final original = this;
    if (original == null) return null;
    return original.length > 10000
        ? '${original.substring(0, 10000)}...'
        : original;
  }
}
