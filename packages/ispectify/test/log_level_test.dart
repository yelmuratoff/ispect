import 'package:ispectify/src/models/log_level.dart';
import 'package:test/test.dart';

void main() {
  group('LogLevel enum order', () {
    test('indices follow severity order: critical(0) > verbose(5)', () {
      // LogLevelRangeFilter relies on index ordering for range comparisons.
      // If this test breaks, update the filter logic accordingly.
      expect(LogLevel.critical.index, 0);
      expect(LogLevel.error.index, 1);
      expect(LogLevel.warning.index, 2);
      expect(LogLevel.info.index, 3);
      expect(LogLevel.debug.index, 4);
      expect(LogLevel.verbose.index, 5);
    });
  });

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
