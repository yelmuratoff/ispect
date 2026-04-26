import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/color_picker/color_scheme_inspector.dart';
import 'package:ispect_layout/src/widgets/color_picker/utils.dart';

void main() {
  group('colorToHexString', () {
    test('formats opaque RGB without alpha by default', () {
      expect(colorToHexString(const Color(0xFFAABBCC)), 'aabbcc');
    });

    test('formats with alpha when requested', () {
      expect(
        colorToHexString(const Color(0x80AABBCC), withAlpha: true),
        '80aabbcc',
      );
    });

    test('pads single-digit channels', () {
      expect(colorToHexString(const Color(0xFF010203)), '010203');
    });
  });

  group('colorToDisplayHex', () {
    test('omits alpha for opaque colours', () {
      expect(colorToDisplayHex(const Color(0xFFFF0000)), '#FF0000');
    });

    test('includes alpha for translucent colours', () {
      expect(colorToDisplayHex(const Color(0x80FF0000)), '#80FF0000');
    });

    test('returns uppercase hex', () {
      expect(colorToDisplayHex(const Color(0xFFabcdef)), '#ABCDEF');
    });
  });

  group('contrastRatio / wcagLevel', () {
    test('white on black is 21:1 (AAA)', () {
      final r = contrastRatio(
        const Color(0xFFFFFFFF),
        const Color(0xFF000000),
      );
      expect(r, closeTo(21.0, 0.01));
      expect(wcagLevel(r), 'AAA');
    });

    test('identical colours have ratio 1.0 (Fail)', () {
      final r = contrastRatio(
        const Color(0xFF808080),
        const Color(0xFF808080),
      );
      expect(r, closeTo(1.0, 0.01));
      expect(wcagLevel(r), 'Fail');
    });

    test('ratio is symmetric', () {
      final a = const Color(0xFF202020);
      final b = const Color(0xFFE0E0E0);
      expect(contrastRatio(a, b), equals(contrastRatio(b, a)));
    });

    test('classifies AA Large boundary at 3.0', () {
      expect(wcagLevel(3.0), 'AA Large');
      expect(wcagLevel(2.99), 'Fail');
    });

    test('classifies AA boundary at 4.5', () {
      expect(wcagLevel(4.5), 'AA');
      expect(wcagLevel(4.49), 'AA Large');
    });

    test('classifies AAA boundary at 7.0', () {
      expect(wcagLevel(7.0), 'AAA');
      expect(wcagLevel(6.99), 'AA');
    });
  });

  group('getPixelFromByteData', () {
    ByteData buildBuffer({
      required int width,
      required int height,
      required List<int> rgba,
    }) {
      final bytes = ByteData(width * height * 4);
      for (var i = 0; i < rgba.length; i++) {
        bytes.setUint8(i, rgba[i]);
      }
      return bytes;
    }

    test('reads RGBA channels at origin', () {
      final bytes = buildBuffer(
        width: 1,
        height: 1,
        rgba: [10, 20, 30, 40],
      );
      final c = getPixelFromByteData(bytes, width: 1, height: 1, x: 0, y: 0);
      expect(c, isNotNull);
      expect(c!.r * 255, closeTo(10, 0.5));
      expect(c.g * 255, closeTo(20, 0.5));
      expect(c.b * 255, closeTo(30, 0.5));
      expect(c.a * 255, closeTo(40, 0.5));
    });

    test('reads correct pixel in 2x2 buffer', () {
      // (0,0)=red, (1,0)=green, (0,1)=blue, (1,1)=white
      final bytes = buildBuffer(
        width: 2,
        height: 2,
        rgba: [
          255,
          0,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          0,
          255,
          255,
          255,
          255,
          255,
          255,
        ],
      );
      expect(
        getPixelFromByteData(bytes, width: 2, height: 2, x: 1, y: 0),
        const Color(0xFF00FF00),
      );
      expect(
        getPixelFromByteData(bytes, width: 2, height: 2, x: 0, y: 1),
        const Color(0xFF0000FF),
      );
      expect(
        getPixelFromByteData(bytes, width: 2, height: 2, x: 1, y: 1),
        const Color(0xFFFFFFFF),
      );
    });

    test('returns null for negative coordinates', () {
      final bytes = ByteData(4);
      expect(
        getPixelFromByteData(bytes, width: 1, height: 1, x: -1, y: 0),
        isNull,
      );
      expect(
        getPixelFromByteData(bytes, width: 1, height: 1, x: 0, y: -1),
        isNull,
      );
    });

    test('returns null for out-of-range coordinates', () {
      final bytes = ByteData(4);
      expect(
        getPixelFromByteData(bytes, width: 1, height: 1, x: 1, y: 0),
        isNull,
      );
      expect(
        getPixelFromByteData(bytes, width: 1, height: 1, x: 0, y: 1),
        isNull,
      );
    });
  });

  group('ColorSchemeInspector', () {
    final scheme = const ColorScheme.light(
      primary: Color(0xFF112233),
      secondary: Color(0xFF445566),
    );

    test('returns matching token name', () {
      expect(
        ColorSchemeInspector.matchingTokens(const Color(0xFF112233), scheme),
        contains('primary'),
      );
    });

    test('returns empty list when no match', () {
      expect(
        ColorSchemeInspector.matchingTokens(const Color(0xFF999999), scheme),
        isEmpty,
      );
    });

    test('caches the reverse lookup per scheme', () {
      // Two queries on the same instance must produce identical results.
      final a = ColorSchemeInspector.matchingTokens(
        const Color(0xFF112233),
        scheme,
      );
      final b = ColorSchemeInspector.matchingTokens(
        const Color(0xFF112233),
        scheme,
      );
      expect(a, equals(b));
    });

    test('legacy identifyColorSchemeMatch returns prefixed string', () {
      final result = ColorSchemeInspector.identifyColorSchemeMatch(
        const Color(0xFF112233),
        scheme,
      );
      expect(result, contains('colorScheme.primary'));
    });

    test('legacy identifyColorSchemeMatch is empty when no match', () {
      expect(
        ColorSchemeInspector.identifyColorSchemeMatch(
          const Color(0xFF999999),
          scheme,
        ),
        '',
      );
    });
  });
}
