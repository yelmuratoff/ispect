// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ISpectDeviceLocalizationFr extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationFr([String locale = 'fr']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Taille du cache : $size';
  }

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get appData => 'Données de l\'application';

  @override
  String totalFilesCount(Object count) {
    return 'Nombre total de fichiers : $count';
  }
}
