import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';
import 'package:ispect_layout/src/widgets/components/box_info_panel_widget.dart';

const _targetKey = ValueKey('target');

void main() {
  group('InspectorOverlay', () {
    testWidgets('drops the panel and stops ticking once the selection '
        'detaches', (tester) async {
      final showTarget = ValueNotifier<bool>(true);
      addTearDown(showTarget.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Inspector(child: child!),
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: showTarget,
                builder: (context, visible, _) => visible
                    ? const SizedBox(
                        key: _targetKey,
                        width: 100,
                        height: 100,
                        child: ColoredBox(color: Colors.blue),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byKey(_targetKey)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BoxInfoPanelWidget), findsOneWidget);

      showTarget.value = false;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(BoxInfoPanelWidget), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('BoxInfoPanelWidget breadcrumb', () {
    testWidgets('keeps the user scroll position when the selection is '
        'unchanged', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Inspector(child: child!),
          home: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: _nest(20)),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byKey(_targetKey)));
      await _settleScroll(tester);

      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(BoxInfoPanelWidget),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(position.axis, Axis.horizontal);
      expect(position.maxScrollExtent, greaterThan(0));
      expect(position.pixels, position.maxScrollExtent);

      position.jumpTo(0);
      await tester.pump();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(const Offset(3, 3));
      await _settleScroll(tester);

      final controller = tester
          .state<InspectorState>(find.byType(Inspector))
          .controller;
      expect(controller.hoveredRenderBoxNotifier.value, isNotNull);
      expect(position.pixels, 0);
    });
  });
}

Future<void> _settleScroll(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _nest(int depth) {
  if (depth == 0) {
    return const SizedBox(
      key: _targetKey,
      width: 20,
      height: 20,
      child: ColoredBox(color: Colors.blue),
    );
  }
  return DecoratedBox(
    decoration: const BoxDecoration(color: Colors.black12),
    child: Padding(padding: const EdgeInsets.all(2), child: _nest(depth - 1)),
  );
}
