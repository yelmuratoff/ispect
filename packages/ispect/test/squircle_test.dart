import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/squircle.dart';

double _outline(ShapeBorder shape, Rect rect) => shape
    .getOuterPath(rect)
    .computeMetrics()
    .fold(0, (sum, metric) => sum + metric.length);

void main() {
  group('ISpectAdaptiveSquircle', () {
    // The collapsed panel button, the smallest box the panel theme paints onto.
    const button = Rect.fromLTWH(0, 0, 64, 64);

    test('caps the radius at half the shortest side', () {
      const asked = ISpectAdaptiveSquircle(radius: 90);
      const fits = ISpectAdaptiveSquircle(radius: 32);

      expect(_outline(asked, button), closeTo(_outline(fits, button), 0.01));
    });

    test('a circular exponent traces a circle', () {
      const circle = ISpectAdaptiveSquircle(radius: 32, exponent: 2);

      expect(_outline(circle, button), closeTo(math.pi * 64, 0.1));
    });

    test('rounds further than the continuous corner it replaces', () {
      const superellipse = ISpectAdaptiveSquircle(radius: 32);
      final continuous = ISpectSquircle.border(radius: 16);

      expect(
        _outline(superellipse, button),
        lessThan(_outline(continuous, button)),
      );
    });

    test('leaves a roomy box at the radius it was given', () {
      const roomy = Rect.fromLTWH(0, 0, 360, 400);

      expect(
        _outline(const ISpectAdaptiveSquircle(radius: 28), roomy),
        lessThan(_outline(const ISpectAdaptiveSquircle(radius: 8), roomy)),
      );
    });

    test('interpolates with its own kind instead of snapping', () {
      const from = ISpectAdaptiveSquircle(radius: 10);
      const to = ISpectAdaptiveSquircle(radius: 30);

      final midpoint = ShapeBorder.lerp(from, to, 0.5)!;

      expect(midpoint, isA<ISpectAdaptiveSquircle>());
      expect((midpoint as ISpectAdaptiveSquircle).radius, 20);
    });
  });
}
