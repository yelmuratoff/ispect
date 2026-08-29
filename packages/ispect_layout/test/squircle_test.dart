import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/squircle.dart';

double _outline(ShapeBorder shape, Rect rect) => shape
    .getOuterPath(rect)
    .computeMetrics()
    .fold(0, (sum, metric) => sum + metric.length);

double _perimeter(Rect rect) => 2 * (rect.width + rect.height);

void main() {
  group('InspectorSquircle', () {
    // draggable_panel parks a tab this narrow in the host package.
    const narrow = Rect.fromLTWH(0, 0, 35, 70);

    test('border keeps the logical radius as the corner radius', () {
      final border = InspectorSquircle.border(radius: 10);

      expect(border.borderRadius, const BorderRadius.all(Radius.circular(10)));
    });

    test('border applies the provided side', () {
      const side = BorderSide(color: Color(0xFF123456), width: 1.5);

      final border = InspectorSquircle.border(side: side);

      expect(border.side, side);
    });

    test('decoration builds a ShapeDecoration with the squircle shape', () {
      final decoration = InspectorSquircle.decoration(
        color: const Color(0xFF222222),
        radius: 8,
      );

      final shape = decoration.shape as RoundedSuperellipseBorder;
      expect(decoration.color, const Color(0xFF222222));
      expect(shape.borderRadius, const BorderRadius.all(Radius.circular(8)));
    });

    test('degrades an oversized corner to a stadium, not a crossed path', () {
      final asked = InspectorSquircle.border(radius: 400);
      final stadium = InspectorSquircle.border(radius: narrow.shortestSide / 2);

      expect(_outline(asked, narrow), closeTo(_outline(stadium, narrow), 0.5));
      expect(_outline(asked, narrow), lessThan(_perimeter(narrow)));
    });
  });
}
