import 'package:ispectify/src/network/filter/sampling_filter.dart';
import 'package:test/test.dart';

void main() {
  group('SamplingFilter', () {
    test('logs every N-th call', () {
      final filter = SamplingFilter<String>(sampleRate: 3);

      // Calls: 1, 2, 3, 4, 5, 6
      expect(filter.apply('a'), isFalse); // 1
      expect(filter.apply('b'), isFalse); // 2
      expect(filter.apply('c'), isTrue); // 3 ← logged
      expect(filter.apply('d'), isFalse); // 4
      expect(filter.apply('e'), isFalse); // 5
      expect(filter.apply('f'), isTrue); // 6 ← logged
    });

    test('sampleRate 1 logs every call', () {
      final filter = SamplingFilter<int>(sampleRate: 1);

      expect(filter.apply(1), isTrue);
      expect(filter.apply(2), isTrue);
      expect(filter.apply(3), isTrue);
    });

    test('assert fires for sampleRate <= 0', () {
      expect(
        () => SamplingFilter<int>(sampleRate: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
