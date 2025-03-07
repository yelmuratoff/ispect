import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/utils/console_utils.dart';

class LoggerSettings {
  LoggerSettings({
    Map<LogLevel, AnsiPen>? colors,
    this.enable = true,
    this.defaultTitle = 'Log',
    this.level = LogLevel.verbose,
    this.lineSymbol = '─',
    this.maxLineWidth = 110,
    this.enableColors = true,
  }) {
    if (colors != null) {
      ConsoleUtils.ansiColors.addAll(colors);
    }
    this.colors.addAll(ConsoleUtils.ansiColors);
  }

  final Map<LogLevel, AnsiPen> colors = ConsoleUtils.ansiColors;

  bool enable;
  final String defaultTitle;
  final LogLevel level;
  final String lineSymbol;
  final int maxLineWidth;
  final bool enableColors;

  LoggerSettings copyWith({
    Map<LogLevel, AnsiPen>? colors,
    String? defaultTitle,
    LogLevel? level,
    String? lineSymbol,
    int? maxLineWidth,
    bool? enableColors,
  }) =>
      LoggerSettings(
        colors: colors ?? this.colors,
        defaultTitle: defaultTitle ?? this.defaultTitle,
        level: level ?? this.level,
        lineSymbol: lineSymbol ?? this.lineSymbol,
        maxLineWidth: maxLineWidth ?? this.maxLineWidth,
        enableColors: enableColors ?? this.enableColors,
      );
}
