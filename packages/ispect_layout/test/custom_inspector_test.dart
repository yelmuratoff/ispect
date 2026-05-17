import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';
import 'package:ispect_layout/src/widgets/panel/inspector_panel.dart';
import 'package:ispect_layout/src/widgets/inspector/overlay.dart';

void main() {
  testWidgets('Inspector uses panelBuilder when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Inspector(
            child: const SizedBox(),
            panelBuilder: (context, controller, child) {
              return Stack(
                children: [
                  child,
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.setMode(
                          controller.modeNotifier.value ==
                                  InspectorMode.inspector
                              ? InspectorMode.none
                              : InspectorMode.inspector,
                        );
                      },
                      child: const Text('Custom Panel'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Custom Panel'), findsOneWidget);

    expect(find.byType(InspectorPanel), findsNothing);

    await tester.tap(find.text('Custom Panel'));
    await tester.pump();

    expect(find.byType(InspectorOverlay), findsOneWidget);
  });
}
