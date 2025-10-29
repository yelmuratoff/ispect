import 'package:ispectify/ispectify.dart';

Future<void> main() async {
  final iSpectify = ISpectLogger(
    options: ISpectLoggerOptions(
      customColors: {
        ISpectifyLogType.info.key: AnsiPen()..magenta(),
        CustomLog.logKey: AnsiPen()..green(),
      },
      customTitles: {
        ISpectifyLogType.info.key: 'i',
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
    iSpectify.handle(
      exception: e,
      stackTrace: st,
      message: 'Exception with',
    );
  }

  iSpectify.logCustom(CustomLog('Something like your own service message'));
}

class CustomLog extends ISpectifyData {
  CustomLog(super.message);

  static const logKey = 'custom_log_key';

  @override
  String? get key => logKey;
}
