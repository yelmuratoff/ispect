import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
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

    testWidgets('the translucent parked panel casts no shadow', (tester) async {
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

      expect(panel.theme?.stashedElevation, 0);
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

    testWidgets('leaving the park opens the panel outright', (tester) async {
      if (!kISpectEnabled) return;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalizations.delegate(),
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pump();

      final controller = tester
          .widget<DraggableActionPanel>(find.byType(DraggableActionPanel))
          .controller!;
      expect(controller.phase, PanelPhase.stashed);

      controller.unstash();
      await tester.pumpAndSettle();

      expect(controller.phase, PanelPhase.expanded);
      expect(find.byType(ActionCell), findsWidgets);
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

  group('ISpect panel and ISpect sheets', () {
    bool isUnder(Object target, RenderObject ancestor) {
      if (target is! RenderObject) return false;
      RenderObject? node = target;
      while (node != null) {
        if (identical(node, ancestor)) return true;
        node = node.parent;
      }
      return false;
    }

    Future<void> pumpLogsWithPanel(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(560, 760)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          builder: (context, child) => ISpectBuilder.wrap(child: child!),
          home: const LogsScreen(options: ISpectOptions()),
        ),
      );
      await tester.pumpAndSettle();
    }

    List<double> panelRowsAt(WidgetTester tester, double x) {
      final host = tester.renderObject(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PanelHost'),
      );
      final rows = <double>[];
      for (var y = 0.0; y < 760; y += 4) {
        final result = HitTestResult();
        WidgetsBinding.instance.hitTestInView(
          result,
          Offset(x, y),
          tester.view.viewId,
        );
        if (result.path.any((entry) => isUnder(entry.target, host))) {
          rows.add(y);
        }
      }
      return rows;
    }

    DraggablePanelController panelController(WidgetTester tester) => tester
        .widget<DraggableActionPanel>(find.byType(DraggableActionPanel))
        .controller!;

    final closeButton = find.descendant(
      of: find.byType(ISpectBottomSheetHeader),
      matching: find.byIcon(Icons.close_rounded),
    );

    testWidgets('the sheet closes from under the parked tab, which comes '
        'back afterwards', (tester) async {
      if (!kISpectEnabled) return;
      await pumpLogsWithPanel(tester);
      final tabRows = panelRowsAt(tester, 530);
      expect(tabRows, isNotEmpty);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      final tabCenter = (tabRows.first + tabRows.last) / 2;
      await tester.dragFrom(
        tester.getCenter(find.byType(ISpectDragHandle)),
        Offset(0, tabCenter - tester.getCenter(closeButton).dy),
      );
      await tester.pumpAndSettle();

      expect(panelRowsAt(tester, 530), isEmpty);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(ISpectBottomSheetHeader), findsNothing);
      expect(panelController(tester).phase, PanelPhase.stashed);
    });

    testWidgets('a panel the host hid stays hidden after a sheet closes', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await pumpLogsWithPanel(tester);
      panelController(tester).hide();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(panelController(tester).phase, PanelPhase.hidden);
    });

    testWidgets('a panel the host hides while a sheet is open stays hidden', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await pumpLogsWithPanel(tester);
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      panelController(tester).hide();
      await tester.pumpAndSettle();
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(panelController(tester).phase, PanelPhase.hidden);
    });

    testWidgets('a sheet steps the panel aside without changing its phase', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await pumpLogsWithPanel(tester);
      final phase = panelController(tester).phase;

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(panelController(tester).phase, phase);
      expect(
        tester
            .widget<DraggableActionPanel>(find.byType(DraggableActionPanel))
            .visible,
        isFalse,
      );

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DraggableActionPanel>(find.byType(DraggableActionPanel))
            .visible,
        isTrue,
      );
    });

    testWidgets('a custom panel builder learns when to step aside', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      final seen = <bool>[];
      tester.view
        ..physicalSize = const Size(560, 760)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          builder: (context, child) => ISpectBuilder.wrap(
            options: ISpectOptions(
              panelBuilder: (context, data) {
                seen.add(data.isVisible);
                return DraggableActionPanel(
                  controller: data.controller,
                  visible: data.isVisible,
                  actions: data.actions,
                  child: data.child,
                );
              },
            ),
            child: child!,
          ),
          home: const LogsScreen(options: ISpectOptions()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(seen.first, isTrue);
      expect(seen.last, isFalse);
    });
  });
}
