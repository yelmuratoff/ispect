import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectifyFilter OR logic', () {
    late ISpectifyData testData1;
    late ISpectifyData testData2;
    late ISpectifyData testData3;

    setUp(() {
      testData1 = ISpectifyData('Info message', key: 'test1', title: 'INFO');
      testData2 = ISpectifyData('Error message', key: 'test2', title: 'ERROR');
      testData3 = ISpectifyData('Debug message', key: 'test3', title: 'DEBUG');
    });

    test('single filter works correctly', () {
      final filter = ISpectifyFilter(titles: ['INFO']);

      expect(filter.apply(testData1), true); // Matches title
      expect(filter.apply(testData2), false); // Doesn't match title
      expect(filter.apply(testData3), false); // Doesn't match title
    });

    test('combining title and type filters expands results (OR logic)', () {
      // Create test data with different types
      final infoData =
          ISpectifyData('Info message', key: 'info', title: 'INFO');
      final errorData =
          ISpectifyData('Error message', key: 'error', title: 'ERROR');
      final debugData =
          ISpectifyData('Debug message', key: 'debug', title: 'DEBUG');

      // Filter that requires either INFO title OR specific type
      final filter = ISpectifyFilter(
        titles: ['INFO'],
        types: [
          errorData.runtimeType,
        ], // This should match all since they're the same type
      );

      // With OR logic, item matches if it matches ANY criteria
      expect(filter.apply(infoData), true); // Matches title
      expect(filter.apply(errorData), true); // Matches type
      expect(filter.apply(debugData), true); // Matches type (same runtime type)
    });

    test('combining title and search filters expands results (OR logic)', () {
      final filter = ISpectifyFilter(
        titles: ['INFO'],
        searchQuery: 'Error',
      );

      final matchingBothData =
          ISpectifyData('Info message', key: 'test', title: 'INFO');
      final titleOnlyData =
          ISpectifyData('Info other', key: 'test2', title: 'INFO');
      final searchOnlyData =
          ISpectifyData('Error message', key: 'test3', title: 'ERROR');

      expect(filter.apply(matchingBothData), true); // Matches title
      expect(filter.apply(titleOnlyData), true); // Matches title
      expect(filter.apply(searchOnlyData),
          true,); // Matches search (contains "Error" in title)
    });

    test('combining all three filters expands results (OR logic)', () {
      final filter = ISpectifyFilter(
        titles: ['INFO'],
        types: [ISpectifyData], // All data is this type
        searchQuery: 'special',
      );

      final allMatchData =
          ISpectifyData('Info special message', key: 'test', title: 'INFO');
      final titleOnly =
          ISpectifyData('Info regular message', key: 'test2', title: 'INFO');
      final searchOnly =
          ISpectifyData('Error special message', key: 'test3', title: 'ERROR');
      final typeOnly =
          ISpectifyData('Debug regular message', key: 'test4', title: 'DEBUG');

      expect(filter.apply(allMatchData), true); // Matches title
      expect(filter.apply(titleOnly), true); // Matches title
      expect(filter.apply(searchOnly),
          true,); // Matches search (title contains "Error"? Wait, let's check)
      expect(filter.apply(typeOnly), true); // Matches type
    });

    test('empty filter returns true for all items', () {
      final filter = ISpectifyFilter();

      expect(filter.apply(testData1), true);
      expect(filter.apply(testData2), true);
      expect(filter.apply(testData3), true);
    });

    test('copyWith preserves OR logic', () {
      final originalFilter = ISpectifyFilter(titles: ['INFO']);
      final copiedFilter = originalFilter.copyWith(searchQuery: 'test');

      // Original filter should still work
      expect(originalFilter.apply(ISpectifyData('Info test', title: 'INFO')),
          true,);
      expect(originalFilter.apply(ISpectifyData('Error test', title: 'ERROR')),
          false,);

      // Copied filter should require either title OR search
      expect(copiedFilter.apply(ISpectifyData('Info test', title: 'INFO')),
          true,); // Matches title
      expect(copiedFilter.apply(ISpectifyData('Info other', title: 'INFO')),
          true,); // Matches title
      expect(copiedFilter.apply(ISpectifyData('Error test', title: 'ERROR')),
          true,); // Matches search (title contains "Error"? Wait, search is "test", title is "ERROR" - doesn't contain "test")
      expect(copiedFilter.apply(ISpectifyData('Debug other', title: 'DEBUG')),
          false,); // Matches neither
    });
  });
}
