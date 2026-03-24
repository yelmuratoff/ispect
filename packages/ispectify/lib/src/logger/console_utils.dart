import 'package:ispectify/ispectify.dart';

/// Static helpers for console output: border lines and ANSI color mapping.
abstract class ConsoleUtils {
  /// Generates a bottom border line of [length] repeated [lineSymbol]s.
  ///
  /// ```dart
  /// ConsoleUtils.bottomLine(5);                    // ─────
  /// ConsoleUtils.bottomLine(5, withCorner: true);  // └─────
  /// ```
  static String bottomLine(
    int length, {
    String lineSymbol = '─',
    bool withCorner = false,
  }) {
    assert(length > 0, 'Line length must be greater than zero.');
    final line = lineSymbol * length;
    return withCorner ? '└$line' : line;
  }

  /// Default gray pen used as a fallback when no specific color is configured.
  static final AnsiPen fallbackPen = AnsiPen()..gray();

  /// Default ANSI colors per [LogLevel].
  static final Map<LogLevel, AnsiPen> ansiColors = Map.unmodifiable({
    LogLevel.critical: AnsiPen()..red(),
    LogLevel.error: AnsiPen()..red(),
    LogLevel.warning: AnsiPen()..yellow(),
    LogLevel.verbose: AnsiPen()..gray(),
    LogLevel.info: AnsiPen()..blue(),
    LogLevel.debug: AnsiPen()..gray(),
  });
}
