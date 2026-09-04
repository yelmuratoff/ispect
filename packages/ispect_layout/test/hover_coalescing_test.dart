import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() {
  testWidgets('hover samples within one frame collapse to the newest one', (
    tester,
  ) async {
    final controller = InspectorController();
    addTearDown(controller.dispose);
    const leftKey = ValueKey<String>('left');
    const rightKey = ValueKey<String>('right');

    await tester.pumpWidget(
      MaterialApp(
        home: Inspector(
          controller: controller,
          isPanelVisible: false,
          child: const Row(
            children: [
              SizedBox(
                key: leftKey,
                width: 100,
                height: 100,
                child: ColoredBox(color: Colors.blue),
              ),
              SizedBox(
                key: rightKey,
                width: 100,
                height: 100,
                child: ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    controller.setMode(InspectorMode.inspector);
    final left = tester.getCenter(find.byKey(leftKey));
    final right = tester.getCenter(find.byKey(rightKey));
    final context = tester.element(find.byKey(leftKey));
    final leftBox = tester.renderObject<RenderBox>(find.byKey(leftKey));
    final rightBox = tester.renderObject<RenderBox>(find.byKey(rightKey));

    var hoverEmissions = 0;
    controller.hoveredRenderBoxNotifier.addListener(() => hoverEmissions++);

    controller
      ..onPointerHoverDebounced(left, context)
      ..onPointerHoverDebounced(right, context)
      ..onPointerHoverDebounced(left, context)
      ..onPointerHoverDebounced(right, context);

    expect(hoverEmissions, 1);
    expect(
      controller.hoveredRenderBoxNotifier.value?.targetRenderBox,
      same(leftBox),
    );

    await tester.pump();

    expect(hoverEmissions, 2);
    expect(
      controller.hoveredRenderBoxNotifier.value?.targetRenderBox,
      same(rightBox),
    );

    controller
      ..onPointerHoverDebounced(left, context)
      ..onPointerHoverDebounced(right, context)
      ..onPointerExit(right);
    await tester.pump();

    expect(controller.hoveredRenderBoxNotifier.value, isNull);
  });
}
