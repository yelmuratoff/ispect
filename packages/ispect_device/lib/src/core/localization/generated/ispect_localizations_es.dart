// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ISpectDeviceLocalizationEs extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationEs([String locale = 'es']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Tamaño del caché: $size';
  }

  @override
  String get clearCache => 'Borrar caché';

  @override
  String get appData => 'Datos de la aplicación';

  @override
  String totalFilesCount(Object count) {
    return 'Cantidad total de archivos: $count';
  }
}
