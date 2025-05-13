// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class ISpectDeviceLocalizationRu extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationRu([String locale = 'ru']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Размер кэша: $size';
  }

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get appData => 'Данные приложения';

  @override
  String totalFilesCount(Object count) {
    return 'Всего файлов: $count';
  }
}
