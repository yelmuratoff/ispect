import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

import '../example/talker_example.dart';

void main() {
  final iSpectify = ISpectiy();
  group('ISpectifyOptions', () {
    setUp(() {
      iSpectify.clearHistory();
    });

    test('Register errors', () async {
      final settings = ISpectifyOptions(
        useConsoleLogs: false,
      );
      iSpectify.configure(
        settings: settings,
        logger: ISpectifyLogger(),
      );
      final httpLog = HttpTalkerLog('Http good');
      iSpectify.logCustom(httpLog);

      expect(
        iSpectify.history.whereType<HttpTalkerLog>().isNotEmpty,
        true,
      );
    });

    test('copyWith', () async {
      final settings = ISpectifyOptions();
      final newSettings = settings.copyWith(
        enabled: false,
        useHistory: false,
        useConsoleLogs: false,
        maxHistoryItems: 999,
      );

      expect(newSettings.enabled, false);
      expect(newSettings.useConsoleLogs, false);
      expect(newSettings.useHistory, false);
      expect(newSettings.maxHistoryItems, 999);
    });

    test('copyWith empty', () async {
      final settings = ISpectifyOptions();
      final newSettings = settings.copyWith();

      expect(newSettings.enabled, true);
      expect(newSettings.useConsoleLogs, true);
      expect(newSettings.useHistory, true);
      expect(newSettings.maxHistoryItems, 1000);
    });

    test('Custom log: verifies custom pen is applied to settings', () async {
      final pen = AnsiPen()..green();

      final settings = ISpectifyOptions(
        useConsoleLogs: false,
        colors: {
          YourCustomLog.logKey: pen,
        },
      );

      final iSpectify = ISpectiy(settings: settings);

      final customLog = YourCustomLog('Custom log message');
      iSpectify.logCustom(customLog);

      expect(
        settings.colors[YourCustomLog.logKey],
        pen,
      );
    });

    test('Custom log: verifies custom title is applied to settings', () async {
      final settings = ISpectifyOptions(
        useConsoleLogs: false,
        titles: {
          YourCustomLog.logKey: 'Custom title',
        },
      );

      final iSpectify = ISpectiy(settings: settings);

      final customLog = YourCustomLog('Custom log message');
      iSpectify.logCustom(customLog);

      expect(
        settings.titles[YourCustomLog.logKey],
        'Custom title',
      );
    });
  });
}

class HttpTalkerLog extends ISpectifyLog {
  HttpTalkerLog(super.message);

  @override
  AnsiPen get pen => AnsiPen()..blue();

  @override
  String generateTextMessage({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    return pen.write(message ?? '');
  }
}
