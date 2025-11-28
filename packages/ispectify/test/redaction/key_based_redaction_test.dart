import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('KeyBasedRedaction', () {
    const strategy = KeyBasedRedaction();

    RedactionRuntime runtime({
      Set<String> sensitive = const {'token'},
      Set<String> fullyMasked = const {},
      bool redactBinary = true,
    }) =>
        RedactionRuntime(
          placeholder: '[REDACTED]',
          redactBinary: redactBinary,
          redactBase64: true,
          sensitiveKeysLower: sensitive,
          sensitiveKeyPatterns: const [],
          fullyMaskedKeyNamesLower: fullyMasked,
          isIgnoredValue: (_) => false,
          isIgnoredKey: (_) => false,
          maskString: (value, {keyName}) => 'MASKED(${value.length})',
          binaryPlaceholder: (len) => '[binary $len bytes]',
          base64Placeholder: (len) => '[base64 ~${len}B]',
          redactUint8List: (data) => Uint8List(data.length),
          looksLikeAuthorizationValue: (_) => false,
          isLikelyBase64: (_) => false,
          isProbablyBinaryString: (_) => false,
        );

    test('masks strings under sensitive keys', () {
      final out = strategy.tryRedact(
        'super-secret',
        runtime: runtime(),
        keyName: 'token',
      );
      expect(out, 'MASKED(12)');
    });

    test('fully masks configured keys', () {
      final out = strategy.tryRedact(
        'apivalue',
        runtime: runtime(
          fullyMasked: const {'apikey'},
          sensitive: const {'apikey'},
        ),
        keyName: 'apiKey',
      );
      expect(out, '[REDACTED]');
    });

    test('redacts binary Uint8List when enabled', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final out = strategy.tryRedact(
        data,
        runtime: runtime(),
        keyName: 'token',
      );
      expect(out, isA<Uint8List>());
      expect((out! as Uint8List).length, 3);
    });

    test('returns placeholder for non-string non-bytes under sensitive key',
        () {
      final out = strategy.tryRedact(
        12345,
        runtime: runtime(),
        keyName: 'token',
      );
      expect(out, '[REDACTED]');
    });

    test('returns null when key is not sensitive', () {
      final out = strategy.tryRedact(
        'value',
        runtime: runtime(),
        keyName: 'notSensitive',
      );
      expect(out, isNull);
    });
  });
}
