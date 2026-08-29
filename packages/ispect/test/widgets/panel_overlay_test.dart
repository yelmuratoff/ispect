import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';

void main() {
  group('ISpect panel overlay', () {
    testWidgets('the panel starts parked against the end edge', (tester) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );

      expect(panel.controller?.phase, PanelPhase.stashed);
      expect(
        panel.controller?.placement,
        const PanelPlacement.stashed(PanelEdge.end),
      );
    });

    testWidgets('every panel face takes ISpect squircle corners', (
      tester,
    ) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );

      expect(panel.theme?.collapsedShape, isA<RoundedSuperellipseBorder>());
      expect(panel.theme?.shape, isA<RoundedSuperellipseBorder>());
      expect(panel.theme?.stashedShape, isA<RoundedSuperellipseBorder>());
      expect(panel.actionTheme?.actionShape, isA<RoundedSuperellipseBorder>());
      expect(
        panel.actionTheme?.buttonStyle?.shape?.resolve({}),
        isA<RoundedSuperellipseBorder>(),
      );
      expect(
        panel.actionTheme?.closeButtonStyle?.shape?.resolve({}),
        isA<RoundedSuperellipseBorder>(),
      );
    });

    testWidgets('the parked tab corner stays inside the tab it is drawn on', (
      tester,
    ) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );
      final tab = panel.theme!.stashedShape!;

      const draggablePanelStashedTab = Rect.fromLTWH(0, 0, 35, 70);
      final perimeter =
          2 *
          (draggablePanelStashedTab.width + draggablePanelStashedTab.height);
      final outline = tab
          .getOuterPath(draggablePanelStashedTab)
          .computeMetrics()
          .fold<double>(0, (sum, metric) => sum + metric.length);

      expect(outline, lessThan(perimeter));
    });

    testWidgets('the parked panel is drawn back into the page', (tester) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );

      expect(panel.theme?.stashedOpacity, lessThan(1));
    });

    testWidgets('the panel outline carries the ISpect divider colour', (
      tester,
    ) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );
      final shape = panel.theme!.shape! as RoundedSuperellipseBorder;

      expect(shape.side.style, BorderStyle.solid);
    });

    testWidgets('a caller-supplied controller keeps its own placement', (
      tester,
    ) async {
      if (!kISpectEnabled) return;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) =>
              ISpectBuilder.wrap(controller: controller, child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('the expanded panel renders its action grid', (tester) async {
      if (!kISpectEnabled) return;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) =>
              ISpectBuilder.wrap(controller: controller, child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      controller.expand();
      await tester.pumpAndSettle();

      expect(find.byType(ActionCell), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the expanded panel is headed by the ISpect title', (
      tester,
    ) async {
      if (!kISpectEnabled) return;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) =>
              ISpectBuilder.wrap(controller: controller, child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      controller.expand();
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ActionPanelHeader),
          matching: find.text('ISpect'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the header close control parks the panel', (tester) async {
      if (!kISpectEnabled) return;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) =>
              ISpectBuilder.wrap(controller: controller, child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      controller.expand();
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(ActionPanelHeader),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.phase, PanelPhase.stashed);
    });

    testWidgets('every built-in action is captioned', (tester) async {
      if (!kISpectEnabled) return;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) =>
              ISpectBuilder.wrap(controller: controller, child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      controller.expand();
      await tester.pumpAndSettle();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );

      expect(panel.actions.map((a) => a.label), everyElement(isNotNull));
      expect(find.text('Logs'), findsOneWidget);
    });

    testWidgets('the panel has no collapsed stage', (tester) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final panel = tester.widget<DraggableActionPanel>(
        find.byType(DraggableActionPanel),
      );

      expect(panel.behavior.collapsible, isFalse);
    });

    testWidgets('the panel parks when the log viewer opens, and stays', (
      tester,
    ) async {
      if (!kISpectEnabled) return;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) =>
              ISpectBuilder.wrap(controller: controller, child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      controller.expand();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ActionCell).first);
      await tester.pumpAndSettle();

      expect(find.byType(LogsScreen), findsOneWidget);
      expect(controller.isExpanded, isFalse);
      expect(controller.phase, isNot(PanelPhase.hidden));
      expect(find.byType(DraggableActionPanel), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(LogsScreen), findsNothing);
      expect(controller.phase, isNot(PanelPhase.hidden));
    });
  });
}
