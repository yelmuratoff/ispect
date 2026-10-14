import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('truncateLeaves', () {
    test('replaces a cyclic reference with a marker', () {
      final cyclic = <String, Object?>{'value': 'x' * 20};
      cyclic['self'] = cyclic;

      final truncated = truncateLeaves(cyclic, maxLength: 4);

      expect(truncated, {
        'value': 'xxxx...',
        'self': JsonValueNormalizer.circularReference,
      });
    });

    test('stops descending at the traversal depth limit', () {
      Object? nested = 'leaf';
      for (var depth = 0; depth < 3; depth++) {
        nested = [nested];
      }

      final truncated = truncateLeaves(nested, maxLength: 10, maxDepth: 2);

      expect(truncated, [
        [JsonValueNormalizer.maxDepthReached],
      ]);
    });

    test('keeps a shared non-cyclic value on every branch', () {
      final shared = ['shared'];

      final truncated = truncateLeaves(
        {'left': shared, 'right': shared},
        maxLength: 10,
      );

      expect(truncated, {
        'left': ['shared'],
        'right': ['shared'],
      });
    });
  });
}
