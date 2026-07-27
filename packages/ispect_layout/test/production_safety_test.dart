import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';

void main() {
  testWidgets(
    'direct layout APIs stay inert without the compile-time flag',
    (tester) async {
      expect(kISpectLayoutEnabled, isFalse);

      final controller = InspectorController(isEnabled: true);
      addTearDown(controller.dispose);
      final initialZoom = controller.zoomScaleNotifier.value;

      controller
        ..setMode(InspectorMode.inspector)
        ..zoomIn();

      expect(controller.isEnabled, isFalse);
      expect(controller.modeNotifier.value, InspectorMode.none);
      expect(controller.zoomScaleNotifier.value, initialZoom);
      expect(controller.effectiveWidgetInspectorShortcutActivators, isEmpty);

      const childKey = ValueKey('production-child');
      await tester.pumpWidget(
        MaterialApp(
          home: Inspector(
            controller: controller,
            isEnabled: true,
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsNothing);
      expect(find.byIcon(Icons.colorize), findsNothing);
      expect(controller.stackKey.currentContext, isNull);
    },
    skip: kISpectLayoutEnabled,
  );
}
