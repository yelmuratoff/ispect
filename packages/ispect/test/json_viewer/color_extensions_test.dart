import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/json_viewer/extensions/color_extensions.dart';

void main() {
  group('JsonColorCalc', () {
    test('contrastText returns black on light backgrounds', () {
      expect(Colors.white.contrastText(), Colors.black);
      expect(const Color(0xFFF0F0F0).contrastText(), Colors.black);
    });

    test('contrastText returns white on dark backgrounds', () {
      expect(Colors.black.contrastText(), Colors.white);
      expect(const Color(0xFF101010).contrastText(), Colors.white);
    });

    test('lighten/darken clamp to range and invert each other approximately',
        () {
      const base = Color(0xFF336699);
      final lighter = base.lighten(0.2);
      final darker = base.darken(0.2);
      expect(lighter.computeLuminance(), greaterThan(base.computeLuminance()));
      expect(darker.computeLuminance(), lessThan(base.computeLuminance()));
    });

    test('withAlphaPercent applies alpha correctly', () {
      final c = Colors.red.withAlphaPercent(0.25);
      expect(c.a, closeTo(0.25, 0.001));
    });

    test('blend mixes colors by factor', () {
      const a = Color(0xFFFF0000);
      const b = Color(0xFF0000FF);
      final mid = a.blend(b);
      expect((mid.r * 255).round(), inInclusiveRange(127, 128));
      expect((mid.b * 255).round(), inInclusiveRange(127, 128));
    });
  });
}
