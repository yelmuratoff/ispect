import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('PatternBasedRedaction', () {
    const strategy = PatternBasedRedaction();

    RedactionRuntime runtime({
      bool base64 = true,
      bool binary = true,
    }) =>
        RedactionRuntime(
          placeholder: '[REDACTED]',
          redactBinary: binary,
          redactBase64: base64,
          sensitiveKeysLower: const {},
          sensitiveKeyPatterns: const [],
          fullyMaskedKeyNamesLower: const {},
          isIgnoredValue: (_) => false,
          isIgnoredKey: (_) => false,
          maskString: (value, {keyName}) => 'MASKED(${value.length})',
          binaryPlaceholder: (len) => '[binary $len bytes]',
          base64Placeholder: (len) => '[base64 ~${len}B]',
          redactUint8List: (data) => data,
          looksLikeAuthorizationValue: (value) =>
              value.startsWith('Bearer ') ||
              RegExp(r'^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$')
                  .hasMatch(value),
          isLikelyBase64: (value) => value == 'SGVsbG8=',
          isProbablyBinaryString: (value) => value == '\u0001\u0002\u0003',
        );

    test('masks authorization-like values', () {
      final out = strategy.tryRedact(
        'Bearer abcdef',
        runtime: runtime(),
        keyName: 'authorization',
      );
      expect(out, 'MASKED(13)');
    });

    test('replaces base64-like strings with placeholder when enabled', () {
      final out = strategy.tryRedact(
        'SGVsbG8=',
        runtime: runtime(),
      );
      expect(out, '[base64 ~8B]');
    });

    test('replaces binary-looking strings with placeholder when enabled', () {
      final out = strategy.tryRedact(
        '\u0001\u0002\u0003',
        runtime: runtime(),
      );
      expect(out, '[binary 3 bytes]');
    });

    test('redacts cookie header value using maskString', () {
      final out = strategy.tryRedact(
        'sid=abc; a=b',
        runtime: runtime(),
        keyName: 'cookie',
      );
      expect(out, 'MASKED(12)');
    });

    test('returns null for non-string nodes', () {
      final out = strategy.tryRedact(42, runtime: runtime());
      expect(out, isNull);
    });
  });
}
