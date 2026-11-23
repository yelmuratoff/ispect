import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ISpect panel unseen errors', () {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    late Directory cacheRoot;
    late ISpectLogger logger;
    late DraggablePanelController controller;

    setUpAll(() {
      cacheRoot = Directory.systemTemp.createTempSync('ispect-badge-');
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, (_) async => cacheRoot.path);
    });
    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, null);
      cacheRoot.deleteSync(recursive: true);
    });

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      ISpect.initialize(logger);
      controller = DraggablePanelController();
    });
    tearDown(() async {
      controller.dispose();
      await ISpect.dispose();
    });

    Future<void> pumpPanel(
      WidgetTester tester, {
      ISpectPanelBuilder? panelBuilder,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          builder: (context, child) => ISpectBuilder.wrap(
            controller: controller,
            options: ISpectOptions(panelBuilder: panelBuilder),
            child: child!,
          ),
          home: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
      await tester.pumpAndSettle();
    }

    DraggableActionPanel panel(WidgetTester tester) =>
        tester.widget<DraggableActionPanel>(find.byType(DraggableActionPanel));

    PanelAction logsAction(WidgetTester tester) => panel(
      tester,
    ).actions.firstWhere((action) => action.icon == Icons.reorder_rounded);

    Color errorColor() => ISpectDefaultPalette.error.pick(isDark: true)!;

    testWidgets('a quiet session shows no error badge', (tester) async {
      if (!kISpectEnabled) return;
      logger.info('started');
      await pumpPanel(tester);

      expect(logsAction(tester).badge, isNull);
      expect(panel(tester).theme?.handleColor, isNot(errorColor()));
      expect(panel(tester).collapsedBuilder, isNull);
    });

    testWidgets('the collapsed panel carries the error count', (tester) async {
      if (!kISpectEnabled) return;
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester);
      logger.error('payment failed');
      await tester.pumpAndSettle();

      final collapsedBadge = find.ancestor(
        of: find.byIcon(panel(tester).icon),
        matching: find.byType(Badge),
      );
      expect(collapsedBadge, findsOneWidget);
      expect(
        find.descendant(of: collapsedBadge, matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('1 error')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('an error logged in the app badges the log viewer action', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await pumpPanel(tester);

      logger
        ..error('payment failed')
        ..info('retrying')
        ..error('payment failed again');
      await tester.pumpAndSettle();

      expect(logsAction(tester).badge?.label, '2');
      expect(logsAction(tester).badge?.color, errorColor());
      expect(logsAction(tester).tooltip, 'Open the log viewer, 2 new errors');
      expect(panel(tester).theme?.handleColor, errorColor());
    });

    testWidgets('errors logged before the panel mounts are counted', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      logger.error('startup failed');
      await pumpPanel(tester);

      expect(logsAction(tester).badge?.label, '1');
    });

    testWidgets('a large count is capped in the badge', (tester) async {
      if (!kISpectEnabled) return;
      await pumpPanel(tester);

      for (var i = 0; i < 120; i++) {
        logger.error('flood $i');
      }
      await tester.pumpAndSettle();

      expect(logsAction(tester).badge?.label, '99+');
      expect(logsAction(tester).tooltip, 'Open the log viewer, 120 new errors');
    });

    testWidgets('opening the log viewer clears the badge', (tester) async {
      if (!kISpectEnabled) return;
      await pumpPanel(tester);
      logger.error('payment failed');
      await tester.pumpAndSettle();

      controller.expand();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionCell).first);
      await tester.pumpAndSettle();
      expect(find.byType(LogsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(logsAction(tester).badge, isNull);
      expect(panel(tester).theme?.handleColor, isNot(errorColor()));
    });

    testWidgets('a logger swapped in after mount keeps the badge counting', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      await pumpPanel(tester);
      logger.error('before the swap');
      await tester.pumpAndSettle();

      final replacement = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      await tester.runAsync(() async {
        ISpect.initialize(replacement, force: true);
        await logger.stream.drain<void>();
      });
      await tester.pumpAndSettle();
      expect(logsAction(tester).badge, isNull);

      replacement.error('after the swap');
      await tester.pumpAndSettle();

      expect(logsAction(tester).badge?.label, '1');
    });

    testWidgets('disposing ISpect clears the badge', (tester) async {
      if (!kISpectEnabled) return;
      await pumpPanel(tester);
      logger.error('payment failed');
      await tester.pumpAndSettle();
      expect(logsAction(tester).badge?.label, '1');

      await tester.runAsync(ISpect.dispose);
      await tester.pumpAndSettle();

      expect(logsAction(tester).badge, isNull);
    });

    testWidgets('a custom panel builder receives the unseen error count', (
      tester,
    ) async {
      if (!kISpectEnabled) return;
      final counts = <int>[];
      await pumpPanel(
        tester,
        panelBuilder: (context, data) {
          counts.add(data.unseenErrorCount);
          return DraggableActionPanel(
            controller: data.controller,
            actions: data.actions,
            child: data.child,
          );
        },
      );

      logger.error('payment failed');
      await tester.pumpAndSettle();

      expect(counts.first, 0);
      expect(counts.last, 1);
    });
  });
}
