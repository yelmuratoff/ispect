import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';
import 'package:ispect_layout/src/widgets/components/box_info_panel_widget.dart';

// class _ColorPickerTestPainter extends CustomPainter {
//   static Color localPositionToColor({
//     required Offset offset,
//     required Size size,
//   }) {
//     return Color.lerp(Colors.blue, Colors.red,
//         (offset.dx + offset.dy) / (size.width + size.height))!;
//   }

//   @override
//   void paint(Canvas canvas, Size size) {
//     for (var x = 0.0; x < size.width; x++) {
//       for (var y = 0.0; y < size.height; y++) {
//         final position = Offset(x, y);

//         canvas.drawRect(
//           Rect.fromLTRB(x, y, x + 1, y + 1),
//           Paint()..color = localPositionToColor(offset: position, size: size),
//         );
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

const _containerKey = ValueKey('container');
const _roundedMaterialChildKey = ValueKey('rounded-material-child');
const _page1ContainerKey = ValueKey('page1-container');
const _page2ContainerKey = ValueKey('page2-container');
const _pushButtonKey = ValueKey('push-page2');
const _rowTextKey = ValueKey('row-text');
const _chipIconKey = ValueKey('chip-icon');
const _chipLabelKey = ValueKey('chip-label');

Widget _buildBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: 200.0,
        height: 400.0,
        child: Stack(
          children: [
            Center(
              child: Container(
                key: _containerKey,
                width: 100.0,
                height: 100.0,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPrecisionBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(
      decimalPlaces: 3,
      child: child!,
    ),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          key: _containerKey,
          width: 100.125,
          height: 100.375,
          decoration: const BoxDecoration(
            color: Colors.blue,
          ),
        ),
      ),
    ),
  );
}

Widget _buildCollapsedPanelBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(
      initialPanelExpanded: false,
      child: child!,
    ),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: const SizedBox.expand(),
    ),
  );
}

Widget _buildCustomShortcutBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(
      controller: InspectorController(
        zoomShortcutActivators: const [
          SingleActivator(
            LogicalKeyboardKey.keyZ,
            alt: true,
            meta: true,
          ),
        ],
      ),
      child: child!,
    ),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: const SizedBox.expand(),
    ),
  );
}

Widget _buildNavigationStackBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) => Stack(
          children: [
            Center(
              child: Container(
                key: _page1ContainerKey,
                width: 100.0,
                height: 100.0,
                color: Colors.blue,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton(
                key: _pushButtonKey,
                onPressed: () => Navigator.of(context).push<void>(
                  PageRouteBuilder<void>(
                    // Non-opaque: the page underneath remains onstage in
                    // Overlay's _RenderTheatre, exposing the pre-fix walk
                    // to its render boxes. The active barrier should
                    // absorb the centre-screen tap regardless.
                    opaque: false,
                    barrierColor: const Color(0x99000000),
                    pageBuilder: (_, __, ___) => Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        key: _page2ContainerKey,
                        width: 30.0,
                        height: 30.0,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                child: const Text('push'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildBreadcrumbBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 80.0,
              height: 40.0,
              child: ColoredBox(
                color: Colors.red,
                child: Center(
                  child: Text(
                    'hello',
                    key: _rowTextKey,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildChipIconBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ActionChip(
          avatar: const SizedBox(
            key: _chipIconKey,
            width: 18.0,
            height: 18.0,
            child: ColoredBox(color: Colors.red),
          ),
          label: const Text(
            'Error',
            key: _chipLabelKey,
          ),
          onPressed: () {},
        ),
      ),
    ),
  );
}

Widget _buildMaterialShapeBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Material(
          color: Colors.orange,
          elevation: 4.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          child: const SizedBox(
            key: _roundedMaterialChildKey,
            width: 120.0,
            height: 48.0,
          ),
        ),
      ),
    ),
  );
}

// const _painterKey = ValueKey('container');
// Widget _buildColorPickerTestBody() {
//   return MaterialApp(
//     builder: (context, child) => Inspector(child: child!),
//     home: Scaffold(
//       backgroundColor: Colors.black,
//       body: SizedBox(
//         width: 200.0,
//         height: 200.0,
//         child: CustomPaint(
//           key: _painterKey,
//           painter: _ColorPickerTestPainter(),
//         ),
//       ),
//     ),
//   );
// }

void main() {
  group('Inspector', () {
    testWidgets('panel shows up properly', (tester) async {
      await tester.pumpWidget(_buildBody());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsOneWidget);
      expect(find.byIcon(Icons.colorize), findsOneWidget);
    });

    testWidgets('panel can be collapsed', (tester) async {
      await tester.pumpWidget(_buildBody());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsOneWidget);
      expect(find.byIcon(Icons.colorize), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsNothing);
      expect(find.byIcon(Icons.colorize), findsNothing);
    });

    testWidgets('panel can be reopened', (tester) async {
      await tester.pumpWidget(_buildBody());
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsNothing);
      expect(find.byIcon(Icons.colorize), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsOneWidget);
      expect(find.byIcon(Icons.colorize), findsOneWidget);
    });

    testWidgets('panel can start collapsed', (tester) async {
      await tester.pumpWidget(_buildCollapsedPanelBody());

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsNothing);
      expect(find.byIcon(Icons.colorize), findsNothing);
    });

    // testWidgets('open panel golden test', (tester) async {
    //   await tester.pumpWidget(_buildBody());

    //   await expectLater(
    //     find.byType(InspectorPanel),
    //     matchesGoldenFile('goldens/inspector_panel_open.png'),
    //   );
    // });

    // testWidgets('closed panel golden test', (tester) async {
    //   await tester.pumpWidget(_buildBody());
    //   await tester.tap(find.byIcon(Icons.chevron_right));
    //   await tester.pump();

    //   await expectLater(
    //     find.byType(InspectorPanel),
    //     matchesGoldenFile('goldens/inspector_panel_closed.png'),
    //   );
    // });
  });

  group('Widget inspector', () {
    testWidgets('can be toggled', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.format_shapes),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      expect(getButton().backgroundColor, Colors.blue);
      expect(getButton().foregroundColor, Colors.white);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);
    });

    testWidgets('can be toggled via keyboard shortcut', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.format_shapes),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.blue);
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);
    });

    testWidgets('zoom can be toggled via keyboard shortcut', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.zoom_in),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.blue);
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);
    });

    testWidgets('supports custom multikey zoom shortcuts', (tester) async {
      await tester.pumpWidget(_buildCustomShortcutBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.zoom_in),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.blue);
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);
    });

    testWidgets('respects decimalPlaces from Inspector', (tester) async {
      await tester.pumpWidget(_buildPrecisionBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final container =
          tester.renderObject(find.byKey(_containerKey)) as RenderBox;
      final position =
          (container.localToGlobal(Offset.zero) & container.size).center;

      await tester.tapAt(position);
      await tester.pump();

      expect(find.text('100.125 × 100.375'), findsWidgets);
    });

    testWidgets('can hit-test a Container', (tester) async {
      await tester.pumpWidget(_buildBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final container =
          tester.renderObject(find.byKey(_containerKey)) as RenderBox;

      final position =
          (container.localToGlobal(Offset.zero) & container.size).center;

      await tester.tapAt(position);
      await tester.pump();

      expect(find.textContaining('DecoratedBox'), findsWidgets);
      expect(find.text('100.0 × 100.0'), findsWidgets);

      await tester.tap(find.byType(BoxInfoPanelWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Padding shown as box-model diagram: individual values rather than LTRB string.
      expect(find.text('50.0'), findsWidgets);
      expect(find.text('150.0'), findsWidgets);
      expect(find.text('border radius'), findsOneWidget);
      expect(find.text('12.0'), findsOneWidget);
    });

    testWidgets('shows shape border radius for Material shapes',
        (tester) async {
      await tester.pumpWidget(_buildMaterialShapeBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final child = tester.renderObject(find.byKey(_roundedMaterialChildKey))
          as RenderBox;

      final position = (child.localToGlobal(Offset.zero) & child.size).center;

      await tester.tapAt(position);
      await tester.pump();

      await tester.tap(find.byType(BoxInfoPanelWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RoundedRectangleBorder'), findsOneWidget);
      expect(find.text('border radius'), findsOneWidget);
      expect(find.text('18.0'), findsOneWidget);
    });

    testWidgets(
        'breadcrumb lets the user reselect an ancestor Row from a Text tap',
        (tester) async {
      await tester.pumpWidget(_buildBreadcrumbBody());

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byKey(_rowTextKey)));
      await tester.pump();

      expect(find.textContaining('Paragraph'), findsWidgets);

      final flexChip = find.text('Flex');
      expect(flexChip, findsOneWidget);

      await tester.tap(flexChip);
      await tester.pump();

      // Active target now matches the Row, not the Text.
      expect(find.textContaining('Flex'), findsWidgets);
      expect(find.text('80.0 × 40.0'), findsWidgets);
    });

    testWidgets(
        "selects a chip's avatar icon instead of routing every tap to the label",
        (tester) async {
      // Material's _RenderChip hit-tests its children at their own centre
      // rather than the actual pointer, which sends every chip tap into the
      // label slot. The enrichment in InspectorUtils.findRenderObjectsAt
      // detects that centre-routing (label entry whose bounds don't contain
      // the pointer) and re-hit-tests the avatar so it ends up on the path.
      await tester.pumpWidget(_buildChipIconBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final avatar = tester.renderObject(find.byKey(_chipIconKey)) as RenderBox;
      await tester
          .tapAt((avatar.localToGlobal(Offset.zero) & avatar.size).center);
      await tester.pump();

      expect(find.text('18.0 × 18.0'), findsWidgets);
      expect(find.textContaining('RenderParagraph'), findsNothing);
    });

    testWidgets(
        'does not hit-test widgets from routes underneath the active one',
        (tester) async {
      await tester.pumpWidget(_buildNavigationStackBody());

      await tester.tap(find.byKey(_pushButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_page2ContainerKey), findsOneWidget);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      // Centre tap lands on the barrier of the top route — the page-1
      // 100×100 container behind it must stay invisible to the inspector.
      final page1 =
          tester.renderObject(find.byKey(_page1ContainerKey)) as RenderBox;
      final position = (page1.localToGlobal(Offset.zero) & page1.size).center;

      await tester.tapAt(position);
      await tester.pump();

      expect(find.text('100.0 × 100.0'), findsNothing);
    });

    // testWidgets('hit-test result golden test', (tester) async {
    //   await tester.pumpWidget(_buildBody());
    //   await tester.tap(find.byIcon(Icons.format_shapes));
    //   await tester.pump();

    //   final container =
    //       tester.renderObject(find.byKey(_containerKey)) as RenderBox;

    //   final position =
    //       (container.localToGlobal(Offset.zero) & container.size).center;

    //   await tester.tapAt(position);
    //   await tester.pump();

    //   await expectLater(
    //     find.byType(BoxInfoPanelWidget),
    //     matchesGoldenFile('./goldens/box_info_panel_widget.png'),
    //   );
    // });
  });

  // group('Color picker', () {
  //   testWidgets('can be toggled', (tester) async {
  //     await tester.pumpWidget(_buildColorPickerTestBody());

  //     final finder = find.ancestor(
  //       of: find.byIcon(Icons.colorize),
  //       matching: find.byType(FloatingActionButton),
  //     );

  //     FloatingActionButton getButton() =>
  //         tester.widget(finder) as FloatingActionButton;

  //     expect(getButton().backgroundColor, Colors.white);
  //     expect(getButton().foregroundColor, Colors.black54);

  //     await tester.tap(find.byIcon(Icons.colorize));
  //     await tester.pumpAndSettle();

  //     expect(getButton().backgroundColor, Colors.blue);
  //     expect(getButton().foregroundColor, Colors.white);

  //     await tester.tap(find.byIcon(Icons.colorize));
  //     await tester.pumpAndSettle();

  //     expect(getButton().backgroundColor, Colors.white);
  //     expect(getButton().foregroundColor, Colors.black54);
  //   });

  //   test('colorToHexString returns right colors', () {
  //     final colors = {
  //       'aaaaaa': const Color(0xFFAAAAAA),
  //       'bbbbbb': const Color(0xFFBBBBBB),
  //       'cccccc': const Color(0xFFCCCCCC),
  //       'dddddd': const Color(0xFFDDDDDD),
  //     };

  //     for (final colorKey in colors.keys) {
  //       final color = colors[colorKey];
  //       expect(colorToHexString(color!), equals(colorKey));
  //     }
  //   });

  //   testWidgets('gets the right colors', (tester) async {
  //     await tester.pumpWidget(_buildColorPickerTestBody());
  //     await tester.tap(find.byIcon(Icons.colorize));

  //     await tester.pumpAndSettle(
  //       const Duration(milliseconds: 100),
  //       EnginePhase.build,
  //     );

  //     await expectLater(
  //       find.byType(InspectorPanel),
  //       matchesGoldenFile('a.png'),
  //     );

  //     // Not the cleanest way to do this, but whatever :P
  //     await tester.sendEventToBinding(
  //       const PointerDownEvent(position: Offset(1.0, 1.0)),
  //     );
  //     await tester.pump();

  //     await tester.sendEventToBinding(
  //       const PointerMoveEvent(
  //         delta: Offset(49.0, 49.0),
  //       ),
  //     );
  //     await tester.pump();

  //     await expectLater(
  //       find.byType(InspectorPanel),
  //       matchesGoldenFile('b.png'),
  //     );

  //     // var previousPosition = Offset.zero;
  //     // for (var x = 0.0; x < 200; x += 10) {
  //     //   for (var y = 0.0; y < 200; y += 10) {
  //     //     final position = Offset(x, y);
  //     //     final expectedColor = _ColorPickerTestPainter.localPositionToColor(
  //     //       offset: position,
  //     //       size: const Size(200.0, 200.0),
  //     //     );

  //     //     await tester.sendEventToBinding(PointerMoveEvent(
  //     //       delta: position - previousPosition,
  //     //     ));

  //     //     previousPosition = position;

  //     //     await tester.pump();

  //     //     final colorHex = colorToHexString(expectedColor);
  //     //     expect(find.text(colorHex), findsOneWidget);
  //     //   }
  //     // }
  //   });
  // });
}
