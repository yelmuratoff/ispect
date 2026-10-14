import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/overlay_painter.dart';
import 'package:ispect_layout/src/widgets/inspector/box_info.dart';

const _targetKey = ValueKey('target');

Widget _positioned(double left) => Directionality(
  textDirection: TextDirection.ltr,
  child: Stack(
    children: [
      Positioned(
        left: left,
        top: 10,
        child: const SizedBox(key: _targetKey, width: 40, height: 40),
      ),
    ],
  ),
);

OverlayPainter _painterFor(BoxInfo info) => OverlayPainter(
  boxInfo: info,
  role: OverlayRole.hovered,
  accentColor: Colors.blue,
  showContainerRenderBox: false,
);

void main() {
  group('OverlayPainter.shouldRepaint', () {
    testWidgets('repaints when the same box moved since the last paint', (
      tester,
    ) async {
      await tester.pumpWidget(_positioned(10));
      final info = BoxInfo(
        targetRenderBox: tester.renderObject<RenderBox>(find.byKey(_targetKey)),
      );
      final before = _painterFor(info);

      await tester.pumpWidget(_positioned(60));
      final after = _painterFor(info);

      expect(after.shouldRepaint(before), isTrue);
    });

    testWidgets('skips repaint when the same box has not moved', (
      tester,
    ) async {
      await tester.pumpWidget(_positioned(10));
      final info = BoxInfo(
        targetRenderBox: tester.renderObject<RenderBox>(find.byKey(_targetKey)),
      );

      expect(_painterFor(info).shouldRepaint(_painterFor(info)), isFalse);
    });
  });
}
