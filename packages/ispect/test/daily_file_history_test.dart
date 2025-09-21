import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  late ISpectifyOptions options;

  setUp(() {
    options = ISpectifyOptions();
    // Initialize ISpect for testing
    ISpect.initialize(ISpectify());
  });

  group('DailyFileLogHistory maxSessionDays edge cases', () {
    test('maxSessionDays = 0 should skip file persistence without crashing',
        () async {
      final history = DailyFileLogHistory(options,
          maxSessionDays: 0, enableAutoSave: false,);

      // Add some data
      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);
      expect(history.history.length, 1);

      // This should not crash and should not create any files
      await history.saveToDailyFile();

      // History should still contain the data (not persisted to file, but kept in memory)
      expect(history.history.length, 1);
    });

    test('maxSessionDays = -1 should skip file persistence without crashing',
        () async {
      final history = DailyFileLogHistory(options,
          maxSessionDays: -1, enableAutoSave: false,);

      // Add some data
      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);
      expect(history.history.length, 1);

      // This should not crash and should not create any files
      await history.saveToDailyFile();

      // History should still contain the data
      expect(history.history.length, 1);
    });

    test('maxSessionDays > 0 should work normally', () async {
      final history = DailyFileLogHistory(options,
          maxSessionDays: 5, enableAutoSave: false,);

      // Add some data
      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);
      expect(history.history.length, 1);

      // This should work normally
      await history.saveToDailyFile();

      // History should still contain the data
      expect(history.history.length, 1);
    });

    test('cleanup methods should handle edge cases gracefully', () async {
      final history = DailyFileLogHistory(options,
          maxSessionDays: 0, enableAutoSave: false,);

      // Test that cleanup is not called when maxSessionDays <= 0
      // This is implicitly tested by the fact that saveToDailyFile doesn't crash

      final testData = ISpectifyData('Test log', key: 'test');
      history.add(testData);

      // Multiple saves should not crash
      await history.saveToDailyFile();
      await history.saveToDailyFile();
      await history.saveToDailyFile();

      expect(history.history.length, 1);
    });
  });
}
