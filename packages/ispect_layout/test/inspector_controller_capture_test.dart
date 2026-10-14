import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';

Future<InspectorController> _pumpInspector(WidgetTester tester) async {
  final controller = InspectorController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Inspector(
        controller: controller,
        isPanelVisible: false,
        child: const ColoredBox(color: Colors.red, child: SizedBox.expand()),
      ),
    ),
  );
  return controller;
}

Future<void> _hoverAndRest(WidgetTester tester, Offset position) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: position - const Offset(5, 5));
  await mouse.moveTo(position);
  await tester.pump();
}

Future<void> _awaitCapture(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  await tester.pump();
}

void main() {
  group('pixel capture', () {
    testWidgets('color picker samples a stationary pointer once the capture '
        'lands', (tester) async {
      final controller = await _pumpInspector(tester);
      await _hoverAndRest(tester, const Offset(120, 120));

      controller.setMode(InspectorMode.colorPicker);
      await _awaitCapture(tester);

      expect(controller.byteDataStateNotifier.value, isNotNull);
      expect(controller.selectedColorStateNotifier.value, isNotNull);
      expect(controller.selectedColorOffsetNotifier.value, isNotNull);
    });

    testWidgets('zoom samples a stationary pointer once the capture lands', (
      tester,
    ) async {
      final controller = await _pumpInspector(tester);
      await _hoverAndRest(tester, const Offset(120, 120));

      controller.setMode(InspectorMode.zoom);
      await _awaitCapture(tester);

      expect(controller.byteDataStateNotifier.value, isNotNull);
      expect(controller.zoomOverlayOffsetNotifier.value, isNotNull);
    });
  });

  group('zoom scale', () {
    late InspectorController controller;

    setUp(() => controller = InspectorController());
    tearDown(() => controller.dispose());

    PointerScrollEvent scroll(double dy) =>
        PointerScrollEvent(scrollDelta: Offset(0, dy));

    test('zoomIn and zoomOut step by one', () {
      final initial = controller.zoomScaleNotifier.value;

      controller.zoomIn();
      expect(controller.zoomScaleNotifier.value, initial + 1);

      controller
        ..zoomOut()
        ..zoomOut();
      expect(controller.zoomScaleNotifier.value, initial - 1);
    });

    test('zoomIn stops at the maximum scale', () {
      for (var i = 0; i < 40; i++) {
        controller.zoomIn();
      }

      expect(controller.zoomScaleNotifier.value, controller.maxZoomScale);
      expect(controller.maxZoomScale, 20);
    });

    test('zoomOut stops at the minimum scale', () {
      for (var i = 0; i < 40; i++) {
        controller.zoomOut();
      }

      expect(controller.zoomScaleNotifier.value, controller.minZoomScale);
      expect(controller.minZoomScale, 1);
    });

    test('clamped steps do not notify listeners', () {
      for (var i = 0; i < 40; i++) {
        controller.zoomIn();
      }
      var notifications = 0;
      controller.zoomScaleNotifier.addListener(() => notifications++);

      controller.zoomIn();

      expect(notifications, 0);
    });

    test('scroll changes the scale only in zoom mode', () {
      final initial = controller.zoomScaleNotifier.value;

      controller.onPointerScroll(scroll(-10));

      expect(controller.zoomScaleNotifier.value, initial);
    });

    testWidgets('scrolling up zooms in and scrolling down zooms out within '
        'bounds', (tester) async {
      final controller = await _pumpInspector(tester);
      controller.setMode(InspectorMode.zoom);
      final initial = controller.zoomScaleNotifier.value;

      controller.onPointerScroll(scroll(-10));
      expect(controller.zoomScaleNotifier.value, initial + 1);

      controller.onPointerScroll(scroll(10));
      controller.onPointerScroll(scroll(10));
      expect(controller.zoomScaleNotifier.value, initial - 1);

      for (var i = 0; i < 40; i++) {
        controller.onPointerScroll(scroll(10));
      }
      expect(controller.zoomScaleNotifier.value, controller.minZoomScale);

      for (var i = 0; i < 40; i++) {
        controller.onPointerScroll(scroll(-10));
      }
      expect(controller.zoomScaleNotifier.value, controller.maxZoomScale);
    });

    testWidgets('leaving zoom mode resets the scale', (tester) async {
      final controller = await _pumpInspector(tester);
      controller
        ..setMode(InspectorMode.zoom)
        ..zoomIn()
        ..zoomIn();
      final zoomed = controller.zoomScaleNotifier.value;

      controller.setMode(InspectorMode.none);

      expect(controller.zoomScaleNotifier.value, lessThan(zoomed));
      expect(controller.zoomScaleNotifier.value, 4);
    });
  });
}
