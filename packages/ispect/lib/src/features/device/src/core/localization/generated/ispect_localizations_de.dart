// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ISpectDeviceLocalizationDe extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationDe([String locale = 'de']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Cache-Größe: $size';
  }

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get appData => 'App-Daten';

  @override
  String totalFilesCount(Object count) {
    return 'Gesamtzahl der Dateien: $count';
  }
}
