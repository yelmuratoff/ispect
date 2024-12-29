import 'package:ispectify/src/logger/src/formatter/formatter.dart';
import 'package:ispectify/src/logger/src/models/log_details.dart';
import 'package:ispectify/src/logger/src/settings.dart';
import 'package:ispectify/src/logger/src/utils/utils.dart';

/// This formatter makes messages colorful
/// if this setting is enabled in the settings [ISpectifyLoggerSettings]
class ExtendedLoggerFormatter implements LoggerFormatter {
  const ExtendedLoggerFormatter();

  @override
  String fmt(LogDetails details, ISpectifyLoggerSettings settings) {
    final underline = ConsoleUtils.getUnderline(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );
    final topline = ConsoleUtils.getTopline(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );
    final msg = details.message?.toString() ?? '';
    final msgBorderedLines = msg.split('\n').map((e) => '│ $e');
    if (!settings.enableColors) {
      return '$topline\n${msgBorderedLines.join('\n')}\n$underline';
    }
    var lines = [topline, ...msgBorderedLines, underline];
    lines = lines.map((e) => details.pen.write(e)).toList();
    final coloredMsg = lines.join('\n');
    return coloredMsg;
  }
}
