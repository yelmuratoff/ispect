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

    testWidgets('the panel collapses when the log viewer opens, and stays', (
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
