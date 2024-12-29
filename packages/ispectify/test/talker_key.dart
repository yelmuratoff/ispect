import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('TalkerKey', () {
    test('returns correct key for each enum value', () {
      expect(ISpectifyLogType.error.key, equals('error'));
      expect(ISpectifyLogType.critical.key, equals('critical'));
      expect(ISpectifyLogType.info.key, equals('info'));
      expect(ISpectifyLogType.debug.key, equals('debug'));
      expect(ISpectifyLogType.verbose.key, equals('verbose'));
      expect(ISpectifyLogType.warning.key, equals('warning'));
      expect(ISpectifyLogType.exception.key, equals('exception'));
      expect(ISpectifyLogType.httpError.key, equals('http-error'));
      expect(ISpectifyLogType.httpRequest.key, equals('http-request'));
      expect(ISpectifyLogType.httpResponse.key, equals('http-response'));
      expect(ISpectifyLogType.blocEvent.key, equals('bloc-event'));
      expect(ISpectifyLogType.blocTransition.key, equals('bloc-transition'));
      expect(ISpectifyLogType.blocClose.key, equals('bloc-close'));
      expect(ISpectifyLogType.blocCreate.key, equals('bloc-create'));
      expect(ISpectifyLogType.route.key, equals('route'));
    });

    test('fromLogLevel returns correct ISpectifyLogType', () {
      expect(ISpectifyLogType.fromLogLevel(LogLevel.error), equals(ISpectifyLogType.error));
      expect(ISpectifyLogType.fromLogLevel(LogLevel.critical), equals(ISpectifyLogType.critical));
      expect(ISpectifyLogType.fromLogLevel(LogLevel.info), equals(ISpectifyLogType.info));
      expect(ISpectifyLogType.fromLogLevel(LogLevel.debug), equals(ISpectifyLogType.debug));
      expect(ISpectifyLogType.fromLogLevel(LogLevel.verbose), equals(ISpectifyLogType.verbose));
      expect(ISpectifyLogType.fromLogLevel(LogLevel.warning), equals(ISpectifyLogType.warning));
    });

    test('fromKey returns correct ISpectifyLogType', () {
      expect(
        ISpectifyLogType.fromKey('error'),
        equals(ISpectifyLogType.error),
      );
      expect(
        ISpectifyLogType.fromKey('critical'),
        equals(ISpectifyLogType.critical),
      );
      expect(
        ISpectifyLogType.fromKey('info'),
        equals(ISpectifyLogType.info),
      );
      expect(
        ISpectifyLogType.fromKey('debug'),
        equals(ISpectifyLogType.debug),
      );
      expect(
        ISpectifyLogType.fromKey('verbose'),
        equals(ISpectifyLogType.verbose),
      );
      expect(
        ISpectifyLogType.fromKey('warning'),
        equals(ISpectifyLogType.warning),
      );
      expect(
        ISpectifyLogType.fromKey('exception'),
        equals(ISpectifyLogType.exception),
      );
      expect(
        ISpectifyLogType.fromKey('http-error'),
        equals(ISpectifyLogType.httpError),
      );
      expect(
        ISpectifyLogType.fromKey('http-request'),
        equals(ISpectifyLogType.httpRequest),
      );
      expect(
        ISpectifyLogType.fromKey('http-response'),
        equals(ISpectifyLogType.httpResponse),
      );
      expect(
        ISpectifyLogType.fromKey('bloc-event'),
        equals(ISpectifyLogType.blocEvent),
      );
      expect(
        ISpectifyLogType.fromKey('bloc-transition'),
        equals(ISpectifyLogType.blocTransition),
      );
      expect(
        ISpectifyLogType.fromKey('bloc-close'),
        equals(ISpectifyLogType.blocClose),
      );
      expect(
        ISpectifyLogType.fromKey('bloc-create'),
        equals(ISpectifyLogType.blocCreate),
      );
      expect(
        ISpectifyLogType.fromKey('route'),
        equals(ISpectifyLogType.route),
      );
    });
  });
}
