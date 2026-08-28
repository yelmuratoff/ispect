import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/squircle.dart';

double _outlineLength(ShapeBorder shape, Rect rect) => shape
    .getOuterPath(rect)
    .computeMetrics()
    .fold(0, (sum, m) => sum + m.length);

void main() {
  group('ISpectAdaptiveSquircle', () {
    // The collapsed panel button, where the bars first showed up.
    const button = Rect.fromLTWH(0, 0, 64, 64);

    test('caps the radius at half the shortest side', () {
      const adaptive = ISpectAdaptiveSquircle(radius: 28);
      final capped = ISpectSquircle.border(radius: 16);

      expect(
        _outlineLength(adaptive, button),
        closeTo(_outlineLength(capped, button), 0.01),
      );
    });

    test('a plain squircle past that half walks a longer outline', () {
      final overshooting = ISpectSquircle.border(radius: 28);

      expect(
        _outlineLength(overshooting, button),
        greaterThan(
          _outlineLength(const ISpectAdaptiveSquircle(radius: 28), button),
        ),
      );
    });

    test('leaves a roomy box at the radius it was given', () {
      const roomy = Rect.fromLTWH(0, 0, 360, 400);
      const adaptive = ISpectAdaptiveSquircle(radius: 28);

      expect(
        _outlineLength(adaptive, roomy),
        closeTo(_outlineLength(ISpectSquircle.border(radius: 28), roomy), 0.01),
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
