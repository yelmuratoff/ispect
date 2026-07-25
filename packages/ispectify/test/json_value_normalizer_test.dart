import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _DiagnosticEvent {
  const _DiagnosticEvent();
}

void main() {
  group('JsonValueNormalizer', () {
    test('preserves structures and stringifies unsupported values', () {
      final normalized = JsonValueNormalizer.normalize(
        <Object?, Object?>{
          1: const _DiagnosticEvent(),
          'values': <Object?>[double.nan, double.infinity],
        },
      );

      expect(normalized, {
        '1': "Instance of '_DiagnosticEvent'",
        'values': ['NaN', 'Infinity'],
      });
    });

    test('replaces circular references with a stable marker', () {
      final value = <String, Object?>{};
      value['self'] = value;

      expect(JsonValueNormalizer.normalize(value), {
        'self': JsonValueNormalizer.circularReference,
      });
    });

    test('stops traversal at the configured depth', () {
      expect(
        JsonValueNormalizer.normalize(
          {
            'nested': {'value': 1},
          },
          maxDepth: 1,
        ),
        {'nested': JsonValueNormalizer.maxDepthReached},
      );
    });

    test('rejects a non-positive maximum depth', () {
      expect(
        () => JsonValueNormalizer.normalize(const {}, maxDepth: 0),
        throwsRangeError,
      );
    });
  });
}
