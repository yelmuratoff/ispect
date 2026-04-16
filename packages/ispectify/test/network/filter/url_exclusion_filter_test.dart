import 'package:ispectify/src/network/filter/url_exclusion_filter.dart';
import 'package:test/test.dart';

void main() {
  group('UrlExclusionFilter', () {
    Uri extractor(String url) => Uri.parse(url);

    test('permits URL not matching any pattern', () {
      final filter = UrlExclusionFilter<String>(
        excludedPatterns: ['/health', RegExp(r'/metrics$')],
        urlExtractor: extractor,
      );

      expect(filter.apply('https://api.example.com/users'), isTrue);
    });

    test('blocks URL matching a string pattern', () {
      final filter = UrlExclusionFilter<String>(
        excludedPatterns: ['/health'],
        urlExtractor: extractor,
      );

      expect(filter.apply('https://api.example.com/health'), isFalse);
    });

    test('blocks URL matching a RegExp pattern', () {
      final filter = UrlExclusionFilter<String>(
        excludedPatterns: [RegExp(r'/metrics$')],
        urlExtractor: extractor,
      );

      expect(filter.apply('https://api.example.com/metrics'), isFalse);
      expect(filter.apply('https://api.example.com/metrics/detail'), isTrue);
    });

    test('empty patterns list permits all URLs', () {
      final filter = UrlExclusionFilter<String>(
        excludedPatterns: [],
        urlExtractor: extractor,
      );

      expect(filter.apply('https://anything.com/path'), isTrue);
    });

    test('blocks if any pattern matches', () {
      final filter = UrlExclusionFilter<String>(
        excludedPatterns: ['/health', '/ready', '/alive'],
        urlExtractor: extractor,
      );

      expect(filter.apply('https://api.example.com/ready'), isFalse);
    });
  });
}
