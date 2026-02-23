import 'package:ispectify/src/models/log_level.dart';
import 'package:test/test.dart';

void main() {
  group('LogLevelX', () {
    test('returns correct developerLevel for verbose', () {
      expect(LogLevel.verbose.developerLevel, 500);
    });

    test('returns correct developerLevel for debug', () {
      expect(LogLevel.debug.developerLevel, 500);
    });

    test('returns correct developerLevel for info', () {
      expect(LogLevel.info.developerLevel, 800);
    });

    test('returns correct developerLevel for warning', () {
      expect(LogLevel.warning.developerLevel, 900);
    });

    test('returns correct developerLevel for error', () {
      expect(LogLevel.error.developerLevel, 1000);
    });

    test('returns correct developerLevel for critical', () {
      expect(LogLevel.critical.developerLevel, 1200);
    });
  });
}
