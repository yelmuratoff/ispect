/// An extension on nullable [String] to provide additional utility methods.
extension ISpectStringExtension on String? {
  /// Capitalizes the first letter of the string.
  ///
  /// - If the string is `null` or empty, it returns an empty string.
  /// - If the string has only one character, it converts it to uppercase.
  /// - Otherwise, it converts the first character to uppercase and keeps the rest unchanged.
  ///
  /// ### Example:
  /// ```dart
  /// print(null.capitalize());       // Output: ''
  /// print(''.capitalize());         // Output: ''
  /// print('a'.capitalize());        // Output: 'A'
  /// print('hello'.capitalize());    // Output: 'Hello'
  /// ```
  ///
  /// Returns the capitalized version of the string.
  String capitalize() {
    final value = this; // Avoid repeated use of `this!`
    if (value == null || value.isEmpty) return '';
    return value.length == 1
        ? value.toUpperCase()
        : '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
