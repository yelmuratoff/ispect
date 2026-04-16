import 'package:ispectify/src/network/filter/status_code_filter.dart';
import 'package:test/test.dart';

void main() {
  group('StatusCodeFilter', () {
    test('permits status codes matching predicate', () {
      final filter = StatusCodeFilter<int>(
        predicate: (code) => code >= 400,
        statusCodeExtractor: (v) => v,
      );

      expect(filter.apply(404), isTrue);
      expect(filter.apply(500), isTrue);
    });

    test('blocks status codes not matching predicate', () {
      final filter = StatusCodeFilter<int>(
        predicate: (code) => code >= 400,
        statusCodeExtractor: (v) => v,
      );

      expect(filter.apply(200), isFalse);
      expect(filter.apply(301), isFalse);
    });

    test('works with range predicate', () {
      final filter = StatusCodeFilter<int>(
        predicate: (code) => code >= 200 && code < 300,
        statusCodeExtractor: (v) => v,
      );

      expect(filter.apply(200), isTrue);
      expect(filter.apply(299), isTrue);
      expect(filter.apply(300), isFalse);
    });
  });
}
