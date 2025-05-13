// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ISpectDeviceLocalizationZh extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationZh([String locale = 'zh']) : super(locale);

  @override
  String cacheSize(Object size) {
    return '缓存大小：$size';
  }

  @override
  String get clearCache => '清除缓存';

  @override
  String get appData => '应用数据';

  @override
  String totalFilesCount(Object count) {
    return '文件总数：$count';
  }
}
