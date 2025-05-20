// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class ISpectDeviceLocalizationHi extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationHi([String locale = 'hi']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'कैश आकार: $size';
  }

  @override
  String get clearCache => 'कैश साफ करें';

  @override
  String get appData => 'ऐप डेटा';

  @override
  String totalFilesCount(Object count) {
    return 'कुल फाइलों की संख्या: $count';
  }
}
