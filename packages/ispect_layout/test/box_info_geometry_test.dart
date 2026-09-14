import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/inspector/box_info.dart';

void main() {
  testWidgets('padding is measured in container coordinates', (tester) async {
    const containerKey = ValueKey('container');
    const targetKey = ValueKey('target');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Transform(
            alignment: Alignment.topLeft,
            transform: Matrix4.diagonal3Values(2, 3, 1),
            child: const SizedBox(
              key: containerKey,
              width: 100,
              height: 100,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 30, 40),
                child: SizedBox(key: targetKey),
              ),
            ),
          ),
        ),
      ),
    );

    final container = tester.renderObject<RenderBox>(find.byKey(containerKey));
    final target = tester.renderObject<RenderBox>(find.byKey(targetKey));
    final info = BoxInfo(
      targetRenderBox: target,
      containerRenderBox: container,
    );

    expect(info.originalPadding, const EdgeInsets.fromLTRB(10, 20, 30, 40));
  });
}
