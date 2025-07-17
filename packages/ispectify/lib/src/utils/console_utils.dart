import 'package:ispectify/ispectify.dart';

/// A utility class for console output formatting.
///
/// The `ConsoleUtils` class provides static methods for generating
/// top and bottom border lines, as well as ANSI color mappings
/// for log levels. This class is non-instantiable.
abstract class ConsoleUtils {
  /// Prevents instantiation of `ConsoleUtils`.
  /// This is a utility class with only static methods.
  ConsoleUtils._();

  /// Generates a bottom border line for console messages.
  ///
  /// This method returns a string consisting of a repeated `lineSymbol`
  /// for the specified `length`. Optionally, a bottom-left corner ('└')
  /// can be added if `withCorner` is `true`.
  ///
  /// ### Example:
  /// ```dart
  /// print(ConsoleUtils.bottomLine(5)); // Output: ─────
  /// print(ConsoleUtils.bottomLine(5, withCorner: true)); // Output: └─────
  /// ```
  ///
  /// - `length`: The number of `lineSymbol` characters in the line.
  /// - `lineSymbol`: The character used to construct the line. Defaults to '─'.
  /// - `withCorner`: If `true`, adds a bottom-left corner symbol. Defaults to `false`.
  ///
  /// Returns:
  /// A formatted string representing the bottom border line.
  static String bottomLine(
    int length, {
    String lineSymbol = '─',
    bool withCorner = false,
  }) {
    assert(length > 0, 'Line length must be greater than zero.');
    final line = lineSymbol * length;
    return withCorner ? '└$line' : line;
  }

  /// ANSI color mapping for different log levels.
  ///
  /// This map associates each `LogLevel` with a corresponding ANSI color.
  static final Map<LogLevel, AnsiPen> ansiColors = {
    LogLevel.critical: AnsiPen()..red(),
    LogLevel.error: AnsiPen()..red(),
    LogLevel.warning: AnsiPen()..yellow(),
    LogLevel.verbose: AnsiPen()..gray(),
    LogLevel.info: AnsiPen()..blue(),
    LogLevel.debug: AnsiPen()..gray(),
  };
}
