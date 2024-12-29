import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

import 'talker_settings_test.dart';

class LikeErrorButNot {}

void main() {
  final iSpectify = ISpectiy(settings: ISpectifyOptions(useConsoleLogs: false));

  setUp(() {
    iSpectify.clearHistory();
  });

  group('ISpectiy', () {
    test('Handle error', () {
      iSpectify.handle(ArgumentError());
      iSpectify.handle(ArgumentError(), StackTrace.current, 'Some error');
      expect(iSpectify.history, isNotEmpty);
      expect(iSpectify.history.length, 2);
      expect(iSpectify.history.first is TalkerError, true);
      expect(iSpectify.history.last is TalkerError, true);
    });

    test('Handle exception', () {
      iSpectify.handle(Exception());
      iSpectify.handle(Exception(), StackTrace.current, 'Some error');
      expect(iSpectify.history, isNotEmpty);
      expect(iSpectify.history.length, 2);
      expect(iSpectify.history.first is TalkerException, true);
      expect(iSpectify.history.last is TalkerException, true);
    });

    test('Handle exception with logs enabled', () {
      iSpectify.configure(
        settings: ISpectifyOptions(),
        logger: ISpectifyLogger(
          output: (message) {},
        ),
      );
      iSpectify.handle(Exception());
      iSpectify.handle(Exception(), StackTrace.current, 'Some error');
      expect(iSpectify.history, isNotEmpty);
      expect(iSpectify.history.length, 2);
      expect(iSpectify.history.first is TalkerException, true);
      expect(iSpectify.history.last is TalkerException, true);
    });

    test('Handle not exception or error', () {
      iSpectify.handle('Text');
      iSpectify.handle(LikeErrorButNot());
      expect(iSpectify.history, isNotEmpty);
      expect(iSpectify.history.length, 2);
      expect(iSpectify.history.first is ISpectifyLog, true);
      expect(iSpectify.history.last is ISpectifyLog, true);
    });

    test('Equality', () {
      final talker1 = ISpectiy();
      final talker2 = ISpectiy();
      expect(talker1, isNot(talker2));
      expect(talker1, talker1);
    });

    test('hashCode', () async {
      final iSpectify = ISpectiy();

      expect(iSpectify.hashCode, isNotNull);
      expect(iSpectify.hashCode, isNot(0));
    });

    test('log', () async {
      const testLogMessage = 'Test log message';
      final iSpectify = ISpectiy(
        logger: ISpectifyLogger(
          output: (message) {},
        ),
      );
      iSpectify.log(testLogMessage);

      expect(iSpectify.history.length, 1);
      expect(
        iSpectify.history.whereType<ISpectifyLog>().length,
        1,
      );
      expect(iSpectify.history.first.message, testLogMessage);
    });

    test('logCustom', () async {
      final iSpectify = ISpectiy(
        logger: ISpectifyLogger(
          output: (message) {},
        ),
      );
      final httpLog = HttpTalkerLog('Http good');
      iSpectify.logCustom(httpLog);

      expect(iSpectify.history.length, 1);
      expect(
        iSpectify.history.whereType<ISpectifyLog>().length,
        1,
      );
      expect(
        iSpectify.history.whereType<HttpTalkerLog>().length,
        1,
      );
      expect(iSpectify.history.first.message, httpLog.message);
    });
  });
}
