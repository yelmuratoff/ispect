import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogType lookups', () {
    test('fromLogLevel returns canonical type', () {
      expect(ISpectLogType.fromLogLevel(LogLevel.error), ISpectLogType.error);
      expect(
        ISpectLogType.fromLogLevel(LogLevel.warning),
        ISpectLogType.warning,
      );
    });

    test('fromKey returns matching enum', () {
      expect(ISpectLogType.fromKey('http-request'), ISpectLogType.httpRequest);
      expect(ISpectLogType.fromKey('missing'), isNull);
    });

    test('isErrorKey matches cached set', () {
      expect(ISpectLogType.isErrorKey('db-error'), isTrue);
      expect(ISpectLogType.isErrorKey('route'), isFalse);
    });
  });
}
