import 'package:talker_flutter/talker_flutter.dart';

/// `SuccessLog` - This class contains the basic structure of the log.
class SuccessLog extends TalkerLog {
  SuccessLog(String super.message);

  @override
  String get title => logKey;

  @override
  String get key => logKey;

  @override
  AnsiPen get pen => logPen;

  static String get logKey => 'success';

  static AnsiPen get logPen => AnsiPen()..magenta();
}
