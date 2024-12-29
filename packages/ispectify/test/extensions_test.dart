import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('TalkerExtensions', () {
    test('HistoryListText', () async {
      final error = TalkerError(ArgumentError());
      final exception = TalkerException(Exception());
      final log = ISpectifyLog('message');

      final data = <ISpectiyData>[error, exception, log];
      final fullMsg = data.text();
      final expectedMsg =
          '${error.generateTextMessage()}\n${exception.generateTextMessage()}\n${log.generateTextMessage()}\n';
      expect(fullMsg, expectedMsg);
    });
  });
}
