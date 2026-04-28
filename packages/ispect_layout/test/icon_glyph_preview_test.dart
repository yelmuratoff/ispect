import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/value_descriptors.dart';

void main() {
  group('describeAsIconGlyphs', () {
    test('returns preview for a MaterialIcons single-glyph TextSpan', () {
      // Icons.arrow_back code point.
      const span = TextSpan(
        text: '',
        style: TextStyle(fontFamily: 'MaterialIcons'),
      );

      final preview = describeAsIconGlyphs(span);

      expect(preview, isNotNull);
      expect(preview!.codePoints, [0xE5C4]);
      expect(preview.fontFamily, 'MaterialIcons');
      expect(preview.codePointsLabel, 'U+E5C4');
      expect(preview.glyphs, '');
    });

    test('returns preview for a CupertinoIcons span', () {
      // CupertinoIcons.back code point.
      const span = TextSpan(
        text: '',
        style: TextStyle(fontFamily: 'CupertinoIcons'),
      );

      expect(describeAsIconGlyphs(span), isNotNull);
    });

    test('returns null for plain text', () {
      const span = TextSpan(text: 'hello');
      expect(describeAsIconGlyphs(span), isNull);
    });

    test('returns null when font family is not an icon font', () {
      // A character in PUA range, but rendered with a normal font — almost
      // certainly not an icon, do not surface as one.
      const span = TextSpan(
        text: '',
        style: TextStyle(fontFamily: 'Roboto'),
      );

      expect(describeAsIconGlyphs(span), isNull);
    });

    test('returns null when any character is outside the Private Use Area', () {
      const span = TextSpan(
        text: ' hi',
        style: TextStyle(fontFamily: 'MaterialIcons'),
      );

      expect(describeAsIconGlyphs(span), isNull);
    });

    test('walks nested children and collects every code point', () {
      const span = TextSpan(
        children: [
          TextSpan(
            text: '',
            style: TextStyle(fontFamily: 'MaterialIcons'),
          ),
          TextSpan(
            text: '',
            style: TextStyle(fontFamily: 'MaterialIcons'),
          ),
        ],
      );

      final preview = describeAsIconGlyphs(span);
      expect(preview, isNotNull);
      expect(preview!.codePoints, [0xE5C4, 0xE5C8]);
      expect(preview.codePointsLabel, 'U+E5C4 U+E5C8');
    });

    test('returns null when one nested child is plain text', () {
      const span = TextSpan(
        children: [
          TextSpan(
            text: '',
            style: TextStyle(fontFamily: 'MaterialIcons'),
          ),
          TextSpan(text: 'label'),
        ],
      );

      expect(describeAsIconGlyphs(span), isNull);
    });
  });
}
