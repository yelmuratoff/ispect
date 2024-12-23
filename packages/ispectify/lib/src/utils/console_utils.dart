/// A utility class for generating styled console lines.
///
/// The [ConsoleUtils] class contains static methods to generate top and bottom
/// lines with optional corner symbols for console output. This class is
/// non-instantiable and only provides static functionality.
final class ConsoleUtils {
  /// Prevents instantiation of [ConsoleUtils].
  /// This is a utility class and should not be instantiated.
  const ConsoleUtils._();

  /// Generates a bottom line for console output.
  ///
  /// This method generates a line of specified [length] using the provided
  /// [lineSymbol]. Optionally, a corner symbol ('└') can be included at
  /// the start of the line if [withCorner] is set to `true`.
  ///
  /// ### Example:
  /// ```dart
  /// print(ConsoleUtils.bottomLine(5)); // Output: ─────
  /// print(ConsoleUtils.bottomLine(5, withCorner: true)); // Output: └─────
  /// ```
  ///
  /// - [length]: The number of [lineSymbol] characters to include in the line.
  /// - [lineSymbol]: The symbol used to construct the line. Defaults to '─'.
  /// - [withCorner]: If `true`, includes a '└' symbol at the beginning. Defaults to `false`.
  ///
  /// Returns:
  /// A string representing the generated bottom line.
  static String bottomLine(
    int length, {
    String lineSymbol = '─',
    bool withCorner = false,
  }) {
    final line = lineSymbol * length;
    if (withCorner) {
      return '└$line';
    }
    return line;
  }

  /// Generates a top line for console output.
  ///
  /// This method generates a line of specified [length] using the provided
  /// [lineSymbol]. Optionally, a corner symbol ('┌') can be included at
  /// the start of the line if [withCorner] is set to `true`.
  ///
  /// ### Example:
  /// ```dart
  /// print(ConsoleUtils.topLine(5)); // Output: ─────
  /// print(ConsoleUtils.topLine(5, withCorner: true)); // Output: ┌─────
  /// ```
  ///
  /// - [length]: The number of [lineSymbol] characters to include in the line.
  /// - [lineSymbol]: The symbol used to construct the line. Defaults to '─'.
  /// - [withCorner]: If `true`, includes a '┌' symbol at the beginning. Defaults to `false`.
  ///
  /// Returns:
  /// A string representing the generated top line.
  static String topLine(
    int length, {
    String lineSymbol = '─',
    bool withCorner = false,
  }) {
    final line = lineSymbol * length;
    if (withCorner) {
      return '┌$line';
    }
    return line;
  }
}
