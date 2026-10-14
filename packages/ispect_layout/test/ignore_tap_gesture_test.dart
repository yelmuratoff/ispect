import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';

const _hostButtonKey = ValueKey('host-button');

void main() {
  testWidgets('single taps stay blocked after a multi-touch gesture', (
    tester,
  ) async {
    var hostPresses = 0;
    final controller = InspectorController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Inspector(
          controller: controller,
          isPanelVisible: false,
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              key: _hostButtonKey,
              onPressed: () => hostPresses++,
              child: const Text('host'),
            ),
          ),
        ),
      ),
    );

    controller.setMode(InspectorMode.inspector);
    await tester.pump();

    final first = await tester.startGesture(const Offset(10, 10), pointer: 1);
    final second = await tester.startGesture(const Offset(30, 30), pointer: 2);
    await second.up();
    await first.up();
    await tester.pump();

    await tester.tap(find.byKey(_hostButtonKey));
    await tester.pump();

    expect(hostPresses, 0);
  });
}
