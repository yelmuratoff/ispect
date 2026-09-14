import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

double _outline(ShapeBorder shape, Rect rect) => shape
    .getOuterPath(rect)
    .computeMetrics()
    .fold(0, (sum, metric) => sum + metric.length);

double _perimeter(Rect rect) => 2 * (rect.width + rect.height);

void main() {
  group('ISpectSquircle', () {
    // draggable_panel parks a tab this narrow, the smallest box ISpect paints.
    const tab = Rect.fromLTWH(0, 0, 35, 70);
    const sheet = Rect.fromLTWH(0, 0, 360, 400);

    test('keeps the panel radius inside the narrowest box it paints on', () {
      final shape = ISpectSquircle.border(
        radius: ISpectConstants.panelBorderRadius,
      );

      expect(_outline(shape, tab), lessThan(_perimeter(tab)));
    });

    test('degrades an oversized corner to a stadium, not a crossed path', () {
      final asked = ISpectSquircle.border(radius: 400);
      final stadium = ISpectSquircle.border(radius: tab.shortestSide / 2);

      expect(_outline(asked, tab), closeTo(_outline(stadium, tab), 0.5));
      expect(_outline(asked, tab), lessThan(_perimeter(tab)));
    });

    test('rounds further the larger the radius it is given', () {
      expect(
        _outline(ISpectSquircle.border(radius: 28), sheet),
        lessThan(_outline(ISpectSquircle.border(radius: 8), sheet)),
      );
    });

    test('interpolates with its own kind instead of snapping', () {
      final from = ISpectSquircle.border(radius: 10);
      final to = ISpectSquircle.border(radius: 30);

      final midpoint = ShapeBorder.lerp(from, to, 0.5)!;

      expect(midpoint, isA<RoundedSuperellipseBorder>());
      expect(
        (midpoint as RoundedSuperellipseBorder).borderRadius
            .resolve(TextDirection.ltr)
            .topLeft
            .x,
        20,
      );
    });
  });
}
