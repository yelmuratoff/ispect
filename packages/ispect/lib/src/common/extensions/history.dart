import 'package:ispectify/ispectify.dart';

extension HistoryListFlutterText on List<ISpectiyData> {
  String get formattedText {
    final sb = StringBuffer();
    for (final data in this) {
      final text = data.textMessage;
      sb
        ..write('\n$text\n')
        ..write(ConsoleUtils.underline(30));
    }
    return sb.toString();
  }
}
