import 'package:talker_flutter/talker_flutter.dart';

extension TalkerDataInterfaceListExt on List<TalkerData> {
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
