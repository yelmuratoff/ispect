import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/ispect_layout.dart';
import 'package:ispect_layout/src/widgets/components/box_info_panel_widget.dart';

const _containerKey = ValueKey('container');
const _roundedMaterialChildKey = ValueKey('rounded-material-child');
const _page1ContainerKey = ValueKey('page1-container');
const _page2ContainerKey = ValueKey('page2-container');
const _pushButtonKey = ValueKey('push-page2');
const _rowTextKey = ValueKey('row-text');
const _chipIconKey = ValueKey('chip-icon');
const _chipLabelKey = ValueKey('chip-label');

Widget _buildBody({int maxRenderTreeClipboardCharacters = 10000}) {
  return MaterialApp(
    builder: (context, child) => Inspector(
      maxRenderTreeClipboardCharacters: maxRenderTreeClipboardCharacters,
      child: child!,
    ),
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

Widget _buildDefaultPrecisionBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          key: _containerKey,
          width: 100.25,
          height: 100.75,
          color: Colors.blue,
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
                    // Non-opaque keeps page 1 onstage, proving the active
                    // barrier blocks render boxes from the route underneath.
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

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF3B82F6));
      expect(getButton().foregroundColor, Colors.white);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);
    });

    testWidgets('can be toggled via keyboard shortcut', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.format_shapes),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF3B82F6));
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);
    });

    testWidgets('zoom can be toggled via keyboard shortcut', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.zoom_in),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF3B82F6));
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);
    });

    testWidgets('supports custom multikey zoom shortcuts', (tester) async {
      await tester.pumpWidget(_buildCustomShortcutBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.zoom_in),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF3B82F6));
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, const Color(0xFF1E1E1E));
      expect(getButton().foregroundColor, Colors.white70);
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

    testWidgets('preserves hundredths with the default precision',
        (tester) async {
      await tester.pumpWidget(_buildDefaultPrecisionBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final container =
          tester.renderObject(find.byKey(_containerKey)) as RenderBox;
      final position =
          (container.localToGlobal(Offset.zero) & container.size).center;

      await tester.tapAt(position);
      await tester.pump();

      expect(find.text('100.25 × 100.75'), findsWidgets);
    });

    testWidgets('render-tree copy honors the configured character budget',
        (tester) async {
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map?)?['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(
        _buildBody(maxRenderTreeClipboardCharacters: 40),
      );
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final container =
          tester.renderObject(find.byKey(_containerKey)) as RenderBox;
      await tester.tapAt(
        (container.localToGlobal(Offset.zero) & container.size).center,
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();

      expect(clipboardText, isNotNull);
      expect(clipboardText, hasLength(40));
      expect(clipboardText, endsWith('\n…'));
      expect(find.textContaining('Copied render tree (40 /'), findsOneWidget);
    });

    test('rejects unsafe render-tree clipboard budgets', () {
      expect(
        () => InspectorController(maxRenderTreeClipboardCharacters: 0),
        throwsArgumentError,
      );
      expect(
        () => InspectorController(
          maxRenderTreeClipboardCharacters:
              InspectorController.maxAllowedRenderTreeClipboardCharacters + 1,
        ),
        throwsArgumentError,
      );
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
      expect(find.text('100.00 × 100.00'), findsWidgets);

      await tester.tap(find.byType(BoxInfoPanelWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('50.00'), findsWidgets);
      expect(find.text('150.00'), findsWidgets);
      expect(find.text('border radius'), findsOneWidget);
      expect(find.text('12.00'), findsOneWidget);
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
      expect(find.text('18.00'), findsOneWidget);
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

      expect(find.textContaining('Flex'), findsWidgets);
      expect(find.text('80.00 × 40.00'), findsWidgets);
    });

    testWidgets(
        "selects a chip's avatar icon instead of routing every tap to the label",
        (tester) async {
      // _RenderChip tests child centers, requiring a second hit test for avatars.
      await tester.pumpWidget(_buildChipIconBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final avatar = tester.renderObject(find.byKey(_chipIconKey)) as RenderBox;
      await tester
          .tapAt((avatar.localToGlobal(Offset.zero) & avatar.size).center);
      await tester.pump();

      expect(find.text('18.00 × 18.00'), findsWidgets);
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

      final page1 =
          tester.renderObject(find.byKey(_page1ContainerKey)) as RenderBox;
      final position = (page1.localToGlobal(Offset.zero) & page1.size).center;

      await tester.tapAt(position);
      await tester.pump();

      expect(find.text('100.00 × 100.00'), findsNothing);
    });
  });
}
