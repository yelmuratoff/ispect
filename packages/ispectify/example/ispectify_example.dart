import 'package:ispectify/ispectify.dart';

Future<void> main() async {
  final iSpectify = ISpectify(
    options: ISpectifyOptions(
      colors: {
        ISpectifyLogType.info.key: AnsiPen()..magenta(),
        CustomLog.logKey: AnsiPen()..green(),
      },
      titles: {
        ISpectifyLogType.info.key: 'i',
        CustomLog.logKey: 'Custom',
      },
    ),
  )
    ..error('The restaurant is closed ❌')
    ..info('Ordering from other restaurant...');

  try {
    throw Exception('Something went wrong');
  } catch (e, st) {
    iSpectify.handle(e, st, 'Exception with');
  }

  iSpectify.logCustom(CustomLog('Something like your own service message'));
}

class CustomLog extends ISpectiyData {
  CustomLog(super.message);

  static const logKey = 'custom_log_key';

  @override
  String? get key => logKey;
}
