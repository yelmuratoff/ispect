import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/models/data.dart';

extension ISpectiyDataListExt on List<ISpectiyData> {
  String text({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    final sb = StringBuffer();
    for (final data in this) {
      sb.write('${data.generateTextMessage(timeFormat: timeFormat)}\n');
    }
    return sb.toString();
  }
}

extension ISpectifyIterableLogTypeModifier<ISpectifyLogType> on Iterable<ISpectifyLogType> {
  ISpectifyLogType? firstWhereOrNull(bool Function(ISpectifyLogType element) test) =>
      cast<ISpectifyLogType?>().firstWhere((v) => v != null && test(v), orElse: () => null);
}
