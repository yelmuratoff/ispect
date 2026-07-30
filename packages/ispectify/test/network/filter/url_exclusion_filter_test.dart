import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _HostileUri implements Uri {
  int pathCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    return Uri.parse('https://spoofed.example.test').runtimeType;
  }

  @override
  String get path {
    pathCalls++;
    throw StateError('hostile path');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('hostile formatter');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('hostile Uri member');
}

void main() {
  group('UrlExclusionFilter', () {
    test('permits URL not matching any pattern', () {
      final filter = UrlExclusionFilter<String>.trustedText(
        excludedPatterns: ['/health', RegExp(r'/metrics$')],
        urlExtractor: (url) => url,
      );

      expect(filter.apply('https://api.example.com/users'), isTrue);
    });

    test('blocks URL matching a string pattern', () {
      final filter = UrlExclusionFilter<String>.trustedText(
        excludedPatterns: ['/health'],
        urlExtractor: (url) => url,
      );

      expect(filter.apply('https://api.example.com/health'), isFalse);
    });

    test('blocks URL matching a RegExp pattern', () {
      final filter = UrlExclusionFilter<String>.trustedText(
        excludedPatterns: [RegExp(r'/metrics$')],
        urlExtractor: (url) => url,
      );

      expect(filter.apply('https://api.example.com/metrics'), isFalse);
      expect(filter.apply('https://api.example.com/metrics/detail'), isTrue);
    });

    test('empty patterns list permits all URLs', () {
      final filter = UrlExclusionFilter<String>.trustedText(
        excludedPatterns: [],
        urlExtractor: (url) => url,
      );

      expect(filter.apply('https://anything.com/path'), isTrue);
    });

    test('blocks if any pattern matches', () {
      final filter = UrlExclusionFilter<String>.trustedText(
        excludedPatterns: ['/health', '/ready', '/alive'],
        urlExtractor: (url) => url,
      );

      expect(filter.apply('https://api.example.com/ready'), isFalse);
    });

    test('suppresses when a trusted text extractor throws', () {
      final filter = UrlExclusionFilter<String>.trustedText(
        excludedPatterns: const ['/health'],
        urlExtractor: (_) => throw StateError('extractor failed'),
      );

      expect(filter.apply('https://api.example.com/users'), isFalse);
    });

    test('suppresses an untrusted Uri without invoking its members', () {
      final uri = _HostileUri();
      final filter = UrlExclusionFilter<Uri>(
        excludedPatterns: const ['/health'],
        urlExtractor: (value) => value,
        captureMode: DiagnosticCaptureMode.strict,
      );

      expect(filter.apply(uri), isFalse);
      expect(uri.toStringCalls, 0);
      expect(uri.pathCalls, 0);
      expect(uri.runtimeTypeCalls, 0);
    });

    test('compatibility constructor filters ordinary Uri values by default',
        () {
      final filter = UrlExclusionFilter<Uri>(
        excludedPatterns: const ['/health'],
        urlExtractor: (value) => value,
      );

      expect(
        filter.apply(Uri.parse('https://api.example.com/users')),
        isTrue,
      );
      expect(
        filter.apply(Uri.parse('https://api.example.com/health')),
        isFalse,
      );
    });
  });
}
