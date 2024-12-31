import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/logger/src/models/log_level.dart';

final _defaultColors = {
  LogLevel.critical: AnsiPen()..red(),
  LogLevel.error: AnsiPen()..red(),
  LogLevel.warning: AnsiPen()..yellow(),
  LogLevel.verbose: AnsiPen()..gray(),
  LogLevel.info: AnsiPen()..blue(),
  LogLevel.debug: AnsiPen()..gray(),
};

class ISpectifyLoggerSettings {
  ISpectifyLoggerSettings({
    Map<LogLevel, AnsiPen>? colors,
    this.enable = true,
    this.defaultTitle = 'Log',
    this.level = LogLevel.verbose,
    this.lineSymbol = '─',
    this.maxLineWidth = 110,
    this.enableColors = true,
  }) {
    if (colors != null) {
      _defaultColors.addAll(colors);
    }
    this.colors.addAll(_defaultColors);
  }

  final Map<LogLevel, AnsiPen> colors = _defaultColors;

  bool enable;
  final String defaultTitle;
  final LogLevel level;
  final String lineSymbol;
  final int maxLineWidth;
  final bool enableColors;

  ISpectifyLoggerSettings copyWith({
    Map<LogLevel, AnsiPen>? colors,
    String? defaultTitle,
    LogLevel? level,
    String? lineSymbol,
    int? maxLineWidth,
    bool? enableColors,
  }) {
    return ISpectifyLoggerSettings(
      colors: colors ?? this.colors,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      level: level ?? this.level,
      lineSymbol: lineSymbol ?? this.lineSymbol,
      maxLineWidth: maxLineWidth ?? this.maxLineWidth,
      enableColors: enableColors ?? this.enableColors,
    );
  }
}
