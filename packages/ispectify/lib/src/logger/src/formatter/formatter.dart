import 'package:ispectify/ispectify.dart';

abstract interface class LoggerFormatter {
  String format(
    LogDetails details,
    ISpectifyLoggerSettings settings,
  );
}

class ExtendedLoggerFormatter implements LoggerFormatter {
  const ExtendedLoggerFormatter();

  @override
  String format(
    LogDetails details,
    ISpectifyLoggerSettings settings,
  ) {
    final topline = ConsoleUtils.topline(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );
    final underline = ConsoleUtils.underline(
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
