// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';

Widget _buildBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: const Scaffold(body: SizedBox.expand()),
  );
}

InspectorController _getController(WidgetTester tester) =>
    tester.state<InspectorState>(find.byType(Inspector)).controller;

void main() {
  group('InspectorMode.isInspecting', () {
    test('covers every widget-inspection mode', () {
      expect(InspectorMode.values.where((mode) => mode.isInspecting), [
        InspectorMode.inspector,
        InspectorMode.inspectAndCompare,
        InspectorMode.compareSelect,
      ]);
    });
  });

  group('Inspector panel toggle', () {
    final inspectorButton = find.widgetWithIcon(
      FloatingActionButton,
      Icons.format_shapes,
    );

    testWidgets('turns inspection off from inspector mode', (tester) async {
      await tester.pumpWidget(_buildBody());
      final controller = _getController(tester);
      controller.setMode(InspectorMode.inspector);
      await tester.pump();

      await tester.tap(inspectorButton);
      await tester.pump();

      expect(controller.modeNotifier.value, InspectorMode.none);
    });

    testWidgets('turns inspection off from inspect-and-compare mode', (
      tester,
    ) async {
      await tester.pumpWidget(_buildBody());
      final controller = _getController(tester);
      controller.setMode(InspectorMode.inspectAndCompare);
      await tester.pump();
      expect(controller.modeNotifier.value, InspectorMode.inspectAndCompare);

      await tester.tap(inspectorButton);
      await tester.pump();

      expect(controller.modeNotifier.value, InspectorMode.none);
    });

    testWidgets('turns inspection on from idle', (tester) async {
      await tester.pumpWidget(_buildBody());
      final controller = _getController(tester);

      await tester.tap(inspectorButton);
      await tester.pump();

      expect(controller.modeNotifier.value, InspectorMode.inspector);
    });
  });
}
