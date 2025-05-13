// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ISpectDeviceLocalizationEn extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationEn([String locale = 'en']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Cache size: $size';
  }

  @override
  String get clearCache => 'Clear cache';

  @override
  String get appData => 'App data';

  @override
  String totalFilesCount(Object count) {
    return 'Total files count: $count';
  }
}
