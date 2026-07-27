import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('PatternBasedRedaction', () {
    const strategy = PatternBasedRedaction();

    RedactionContext context({
      bool base64 = true,
      bool binary = true,
    }) =>
        RedactionContext(
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
          redactUint8List: (data) => Uint8List(data.length),
          looksLikeAuthorizationValue: (value) =>
              value.startsWith('Bearer ') ||
              RegExp(r'^[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}$')
                  .hasMatch(value),
          isLikelyBase64: (value) => value == 'SGVsbG8=',
          isProbablyBinaryString: (value) => value == '\u0001\u0002\u0003',
        );

    test('masks authorization-like values', () {
      final out = strategy.tryRedact(
        'Bearer abcdef',
        context: context(),
        keyName: 'authorization',
      );
      expect(out, 'MASKED(13)');
    });

    test('replaces base64-like strings with placeholder when enabled', () {
      final out = strategy.tryRedact(
        'SGVsbG8=',
        context: context(),
      );
      expect(out, '[base64 ~8B]');
    });

    test('replaces binary-looking strings with placeholder when enabled', () {
      final out = strategy.tryRedact(
        '\u0001\u0002\u0003',
        context: context(),
      );
      expect(out, '[binary 3 bytes]');
    });

    test('redacts Uint8List when redactBinary is true', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final out = strategy.tryRedact(
        data,
        context: context(),
      );
      expect(out, isA<Uint8List>());
      expect((out! as Uint8List).length, 4);
    });

    test('redacts all supported typed binary containers by byte length', () {
      final values = <Object>[
        Int8List.fromList([-1, 2, 3]),
        Uint16List.fromList([256, 512]),
        ByteData(4)..setUint32(0, 0x01020304),
        Uint8List.fromList([4, 5, 6, 7, 8]).buffer,
      ];

      for (final value in values) {
        final expectedLength = value is ByteBuffer
            ? value.lengthInBytes
            : (value as TypedData).lengthInBytes;
        final out = strategy.tryRedact(value, context: context());

        expect(out, isA<Uint8List>());
        expect((out! as Uint8List).length, expectedLength);
      }
    });

    test('returns null for Uint8List when redactBinary is false', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final out = strategy.tryRedact(
        data,
        context: context(binary: false),
      );
      expect(out, isNull);
    });

    test('leaves supported typed binary containers to fallback when disabled',
        () {
      final values = <Object>[
        Int8List.fromList([-1, 2, 3]),
        Uint16List.fromList([256, 512]),
        ByteData(4)..setUint32(0, 0x01020304),
        Uint8List.fromList([4, 5, 6]).buffer,
      ];

      for (final value in values) {
        expect(
          strategy.tryRedact(value, context: context(binary: false)),
          isNull,
        );
      }
    });

    test('returns null for non-string non-binary nodes', () {
      final out = strategy.tryRedact(42, context: context());
      expect(out, isNull);
    });
  });
}
