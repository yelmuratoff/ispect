import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectFilter OR logic', () {
    late ISpectLogData testData1;
    late ISpectLogData testData2;
    late ISpectLogData testData3;

    setUp(() {
      testData1 = ISpectLogData('Info message', key: 'INFO');
      testData2 = ISpectLogData('Error message', key: 'ERROR');
      testData3 = ISpectLogData('Debug message', key: 'DEBUG');
    });

    test('single filter works correctly', () {
      final filter = ISpectFilter(logTypeKeys: ['INFO']);

      expect(filter.apply(testData1), true); // Matches key
      expect(filter.apply(testData2), false); // Doesn't match key
      expect(filter.apply(testData3), false); // Doesn't match key
    });

    test('combining logTypeKey and type filters expands results (OR logic)',
        () {
      final infoData = ISpectLogData('Info message', key: 'info');
      final errorData = ISpectLogData('Error message', key: 'error');
      final debugData = ISpectLogData('Debug message', key: 'debug');

      // Filter that requires either INFO key OR specific type
      final filter = ISpectFilter(
        logTypeKeys: ['info'],
        types: [
          errorData.runtimeType,
        ], // This should match all since they're the same type
      );

      // With OR logic, item matches if it matches ANY criteria
      expect(filter.apply(infoData), true); // Matches key
      expect(filter.apply(errorData), true); // Matches type
      expect(filter.apply(debugData), true); // Matches type (same runtime type)
    });

    test('combining logTypeKey and search filters expands results (OR logic)',
        () {
      final filter = ISpectFilter(
        logTypeKeys: ['info'],
        searchQuery: 'Error',
      );

      final matchingBothData = ISpectLogData('Info message', key: 'info');
      final keyOnlyData = ISpectLogData('Info other', key: 'info');
      final searchOnlyData = ISpectLogData('Error message', key: 'error');

      expect(filter.apply(matchingBothData), true); // Matches key
      expect(filter.apply(keyOnlyData), true); // Matches key
      expect(
        filter.apply(searchOnlyData),
        true,
      ); // Matches search (contains "Error")
    });

    test('combining all three filters expands results (OR logic)', () {
      final filter = ISpectFilter(
        logTypeKeys: ['info'],
        types: [ISpectLogData], // All data is this type
        searchQuery: 'special',
      );

      final allMatchData = ISpectLogData('Info special message', key: 'info');
      final keyOnly = ISpectLogData('Info regular message', key: 'info');
      final searchOnly = ISpectLogData(
        'Error special message',
        key: 'error',
      );
      final typeOnly = ISpectLogData(
        'Debug regular message',
        key: 'debug',
      );

      expect(filter.apply(allMatchData), true); // Matches key
      expect(filter.apply(keyOnly), true); // Matches key
      expect(filter.apply(searchOnly), true); // Matches search
      expect(filter.apply(typeOnly), true); // Matches type
    });

    test('empty filter returns true for all items', () {
      final filter = ISpectFilter();

      expect(filter.apply(testData1), true);
      expect(filter.apply(testData2), true);
      expect(filter.apply(testData3), true);
    });

    test('copyWith preserves OR logic', () {
      final originalFilter = ISpectFilter(logTypeKeys: ['INFO']);
      final copiedFilter = originalFilter.copyWith(searchQuery: 'test');

      // Original filter should still work
      expect(
        originalFilter.apply(ISpectLogData('Info test', key: 'INFO')),
        true,
      );
      expect(
        originalFilter.apply(ISpectLogData('Error test', key: 'ERROR')),
        false,
      );

      // Copied filter should require either key OR search
      expect(
        copiedFilter.apply(ISpectLogData('Info test', key: 'INFO')),
        true,
      ); // Matches key
      expect(
        copiedFilter.apply(ISpectLogData('Info other', key: 'INFO')),
        true,
      ); // Matches key
      expect(
        copiedFilter.apply(ISpectLogData('Error test', key: 'ERROR')),
        true,
      ); // Matches search ("test" in message)
      expect(
        copiedFilter.apply(ISpectLogData('Debug other', key: 'DEBUG')),
        false,
      ); // Matches neither
    });
  });

  group('LogLevelRangeFilter', () {
    test('default filter allows all log levels', () {
      final filter = LogLevelRangeFilter();

      expect(filter.shouldLog('Critical message', LogLevel.critical), true);
      expect(filter.shouldLog('Error message', LogLevel.error), true);
      expect(filter.shouldLog('Warning message', LogLevel.warning), true);
      expect(filter.shouldLog('Info message', LogLevel.info), true);
      expect(filter.shouldLog('Debug message', LogLevel.debug), true);
      expect(filter.shouldLog('Verbose message', LogLevel.verbose), true);
    });

    test('custom range filters correctly', () {
      final filter = LogLevelRangeFilter(
        minLevel: LogLevel.error,
        maxLevel: LogLevel.warning,
      );

      expect(
        filter.shouldLog('Critical message', LogLevel.critical),
        false,
      ); // Below range
      expect(
        filter.shouldLog('Error message', LogLevel.error),
        true,
      ); // In range
      expect(
        filter.shouldLog('Warning message', LogLevel.warning),
        true,
      ); // In range
      expect(
        filter.shouldLog('Info message', LogLevel.info),
        false,
      ); // Above range
      expect(
        filter.shouldLog('Debug message', LogLevel.debug),
        false,
      ); // Above range
      expect(
        filter.shouldLog('Verbose message', LogLevel.verbose),
        false,
      ); // Above range
    });

    test('throws ArgumentError for invalid range', () {
      expect(
        () => LogLevelRangeFilter(
          minLevel: LogLevel.debug,
          maxLevel: LogLevel.critical,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('single level filter works', () {
      final filter = LogLevelRangeFilter(
        minLevel: LogLevel.error,
        maxLevel: LogLevel.error,
      );

      expect(filter.shouldLog('Critical message', LogLevel.critical), false);
      expect(filter.shouldLog('Error message', LogLevel.error), true);
      expect(filter.shouldLog('Warning message', LogLevel.warning), false);
    });
  });
}
