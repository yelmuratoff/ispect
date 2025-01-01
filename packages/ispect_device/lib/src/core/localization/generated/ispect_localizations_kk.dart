import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class ISpectDeviceLocalizationKk extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationKk([String locale = 'kk']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Кэш өлшемі: $size';
  }

  @override
  String get clearCache => 'Кэшті тазарту';

  @override
  String get appData => 'Қолданба деректері';

  @override
  String totalFilesCount(Object count) {
    return 'Файлдар саны: $count';
  }
}
