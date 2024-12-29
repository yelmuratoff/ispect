import 'package:ispectify/ispectify.dart';

extension ISpectifyDataInterfaceListExt on List<ISpectiyData> {
  /// The method allows you to get
  /// full text of logs or history
  String formattedText({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    final sb = StringBuffer();
    for (final data in this) {
      sb
        ..write('----------------------------------------\n')
        ..write('${data.generateTextMessage(timeFormat: timeFormat)}\n');
    }
    return sb.toString();
  }
}
