// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class ISpectDeviceLocalizationAr extends ISpectDeviceLocalization {
  ISpectDeviceLocalizationAr([String locale = 'ar']) : super(locale);

  @override
  String cacheSize(Object size) {
    return 'حجم الذاكرة المؤقتة: $size';
  }

  @override
  String get clearCache => 'مسح الذاكرة المؤقتة';

  @override
  String get appData => 'بيانات التطبيق';

  @override
  String totalFilesCount(Object count) {
    return 'إجمالي عدد الملفات: $count';
  }
}
