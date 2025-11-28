import 'package:ispectify/ispectify.dart';

Future<void> main() async {
  final logger = ISpectLogger(
    options: ISpectLoggerOptions(
      customColors: {
        ISpectLogType.info.key: AnsiPen()..magenta(),
        CustomLog.logKey: AnsiPen()..green(),
      },
      customTitles: {
        ISpectLogType.info.key: 'i',
        CustomLog.logKey: 'Custom',
      },
    ),
  )
    ..error('The restaurant is closed ❌')
    ..info('Ordering from other restaurant...')
    ..provider('Provider is ready')
    ..good('The food is ready ✅')
    ..track(
      'User clicked on the button',
      analytics: 'Amplitude',
      parameters: {'button': 'order'},
    );

  try {
    throw Exception('Something went wrong');
  } catch (e, st) {
    logger.handle(
      exception: e,
      stackTrace: st,
      message: 'Exception with',
    );
  }

  logger.logData(CustomLog('Something like your own service message'));
}

class CustomLog extends ISpectLogData {
  CustomLog(super.message);

  static const logKey = 'custom_log_key';

  @override
  String? get key => logKey;
}
