import 'package:ispectify/ispectify.dart';

class ISpectifyLog extends ISpectiyData {
  ISpectifyLog(
    super.message, {
    super.key,
    super.title,
    super.exception,
    super.error,
    super.stackTrace,
    super.time,
    super.pen,
    super.logLevel,
    super.data,
  });

  @override
  String get textMessage => '$messageText$exceptionText$stackTraceText';
}
