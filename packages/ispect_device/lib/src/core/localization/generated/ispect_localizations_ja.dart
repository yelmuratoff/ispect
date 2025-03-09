// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class ISpectDeviceLocalizationJa extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationJa([String locale = 'ja']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'キャッシュサイズ: $size';
  }

  @override
  String get clearCache => 'キャッシュをクリア';

  @override
  String get appData => 'アプリデータ';

  @override
  String totalFilesCount(Object count) {
    return '総ファイル数: $count';
  }
}
