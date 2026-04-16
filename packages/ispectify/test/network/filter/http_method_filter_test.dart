import 'package:ispectify/src/network/filter/http_method_filter.dart';
import 'package:test/test.dart';

void main() {
  group('HttpMethodFilter', () {
    test('permits allowed methods', () {
      final filter = HttpMethodFilter<String>(
        allowedMethods: {'GET', 'POST'},
        methodExtractor: (v) => v,
      );

      expect(filter.apply('GET'), isTrue);
      expect(filter.apply('POST'), isTrue);
    });

    test('blocks disallowed methods', () {
      final filter = HttpMethodFilter<String>(
        allowedMethods: {'GET'},
        methodExtractor: (v) => v,
      );

      expect(filter.apply('POST'), isFalse);
      expect(filter.apply('DELETE'), isFalse);
    });

    test('empty allowedMethods blocks all', () {
      final filter = HttpMethodFilter<String>(
        allowedMethods: {},
        methodExtractor: (v) => v,
      );

      expect(filter.apply('GET'), isFalse);
    });

    test('comparison is case-sensitive', () {
      final filter = HttpMethodFilter<String>(
        allowedMethods: {'GET'},
        methodExtractor: (v) => v,
      );

      expect(filter.apply('get'), isFalse);
    });
  });
}
