import 'package:ispectify/ispectify.dart';

Future<void> main() async {
  final iSpectify = ISpectiy(
    settings: ISpectifyOptions(
      colors: {
        ISpectifyLogType.info.key: AnsiPen()..magenta(),
        YourCustomLog.logKey: AnsiPen()..green(),
      },
      titles: {
        ISpectifyLogType.exception.key: 'Whatever you want',
        ISpectifyLogType.error.key: 'E',
        ISpectifyLogType.info.key: 'i',
        YourCustomLog.logKey: 'Custom',
      },
    ),
  );

  /// Logs with LogLevel
  // iSpectify.warning('The pizza is over 😥');
  // iSpectify.debug('Thinking about order new one 🤔');
  iSpectify.error('The restaurant is closed ❌');
  iSpectify.info('Ordering from other restaurant...');
  // iSpectify.verbose('Payment started...');
  // iSpectify.info('Payment completed! Waiting for pizza 🍕');

  /// [Exception]'s and [Error]'s handling
  try {
    throw Exception('Something went wrong');
  } catch (e, st) {
    iSpectify.handle(e, st, 'Exception with');
  }

  /// Custom logs
  iSpectify.logCustom(YourCustomLog('Something like your own service message'));
}

class YourCustomLog extends ISpectifyLog {
  YourCustomLog(super.message);

  /// Your own log key (for color customization in settings)
  static const logKey = 'custom_log_key';

  @override
  String? get key => logKey;
}
