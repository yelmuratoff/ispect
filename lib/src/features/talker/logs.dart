import 'package:talker_flutter/talker_flutter.dart';

/// `GoodLog` - This class contains the basic structure of the log.
class GoodLog extends TalkerLog {
  GoodLog(String super.message);

  @override
  String get title => logKey;

  @override
  String get key => logKey;

  @override
  AnsiPen get pen => logPen;

  static String get logKey => 'good';

  static AnsiPen get logPen => AnsiPen()..green();
}

/// `AnalyticsLog` - This class contains the analytics log.
class AnalyticsLog extends TalkerLog {
  AnalyticsLog(super.message, {this.analytics});

  final String? analytics;

  @override
  String get title => analytics ?? logKey;

  @override
  String get key => logKey;

  @override
  AnsiPen get pen => logPen;

  static String get logKey => 'analytics';

  static AnsiPen get logPen => AnsiPen()..yellow();
}

/// `RouteLog` - This class contains the route log.
class RouteLog extends TalkerLog {
  RouteLog(String super.message);

  @override
  String get title => logKey;

  @override
  String get key => logKey;

  @override
  AnsiPen get pen => logPen;

  static String get logKey => 'route';

  static AnsiPen get logPen => AnsiPen()..rgb(r: 0.5, g: 0.5);
}

/// `ProviderLog` - This class contains the provider log.
class ProviderLog extends TalkerLog {
  ProviderLog(String super.message, {super.exception, super.stackTrace});

  @override
  String get title => logKey;

  @override
  String get key => logKey;

  @override
  AnsiPen get pen => logPen;

  static String get logKey => 'provider';

  static AnsiPen get logPen => AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9);
}

/// `PrintLog` - This class contains the print log.
class PrintLog extends TalkerLog {
  PrintLog(String super.message);

  @override
  String get title => logKey;

  @override
  String get key => logKey;

  @override
  AnsiPen get pen => logPen;

  static String get logKey => 'print';

  static AnsiPen get logPen => AnsiPen()..blue();
}
