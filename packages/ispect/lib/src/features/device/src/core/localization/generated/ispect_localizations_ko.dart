// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class ISpectDeviceLocalizationKo extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationKo([String locale = 'ko']) : super(locale);

  @override
  String cacheSize(Object size) {
    return '캐시 크기: $size';
  }

  @override
  String get clearCache => '캐시 지우기';

  @override
  String get appData => '앱 데이터';

  @override
  String totalFilesCount(Object count) {
    return '총 파일 수: $count';
  }
}
