// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class ISpectDeviceLocalizationPt extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationPt([String locale = 'pt']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'Tamanho do cache: $size';
  }

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get appData => 'Dados do aplicativo';

  @override
  String totalFilesCount(Object count) {
    return 'Contagem total de arquivos: $count';
  }
}
