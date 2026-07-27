import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() {
  testWidgets(
    'one pointer sample emits one consolidated inspect state',
    (tester) async {
      final controller = InspectorController();
      addTearDown(controller.dispose);
      const targetKey = ValueKey<String>('pointer-target');

      await tester.pumpWidget(
        MaterialApp(
          home: Inspector(
            controller: controller,
            isPanelVisible: false,
            child: const Center(
              child: SizedBox(
                key: targetKey,
                width: 100,
                height: 100,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      controller.setMode(InspectorMode.inspector);
      final pointer = tester.getCenter(find.byKey(targetKey));
      final context = tester.element(find.byKey(targetKey));
      controller.onPointerHoverDebounced(pointer, context);
      final hovered = controller.hoveredRenderBoxNotifier.value;
      expect(hovered, isNotNull);

      controller.setMode(InspectorMode.inspectAndCompare);
      controller.hoveredRenderBoxNotifier.value = hovered;

      var stateEmissions = 0;
      var hoveredEmissions = 0;
      var comparedEmissions = 0;
      controller.stateNotifier.addListener(() => stateEmissions++);
      controller.hoveredRenderBoxNotifier.addListener(
        () => hoveredEmissions++,
      );
      controller.comparedRenderBoxNotifier.addListener(
        () => comparedEmissions++,
      );

      controller.onPointerHoverDebounced(pointer, context);

      expect(hoveredEmissions, 1);
      expect(comparedEmissions, 1);
      expect(stateEmissions, 1);

      stateEmissions = 0;
      controller.setMode(InspectorMode.none);

      expect(stateEmissions, 1);
    },
  );
}
