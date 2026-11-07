import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';

void main() {
  group('LogsScreen beside a sibling focus scope', () {
    const siblingKey = ValueKey('sibling-field');

    setUp(() {
      ISpect.initialize(
        ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      );
      addTearDown(ISpect.dispose);
    });

    Future<void> pumpSplitView(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(2400, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ISpectScopeController(
          model: ISpectScopeModel(isISpectEnabled: true),
          child: MaterialApp(
            localizationsDelegates: ISpectLocalization.localizationDelegates,
            supportedLocales: ISpectLocalization.supportedLocales,
            home: const Row(
              children: [
                Expanded(
                  child: Material(
                    child: FocusScope(child: TextField(key: siblingKey)),
                  ),
                ),
                Expanded(
                  child: FocusScope(
                    child: LogsScreen(options: ISpectOptions()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder searchField() => find.descendant(
      of: find.byType(LogsScreen),
      matching: find.byType(EditableText),
    );

    FocusNode searchNode(WidgetTester tester) =>
        tester.widget<EditableText>(searchField()).focusNode;

    FocusNode siblingNode(WidgetTester tester) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(siblingKey),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode;

    FocusScopeNode logsScope(WidgetTester tester) =>
        FocusScope.of(tester.element(find.byType(LogsScreen)));

    Future<void> pressSearchShortcut(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    testWidgets('leaving search for the sibling pane keeps focus there', (
      tester,
    ) async {
      await pumpSplitView(tester);
      await tester.tap(searchField());
      await tester.pumpAndSettle();
      expect(searchNode(tester).hasFocus, isTrue);

      await tester.tap(find.byKey(siblingKey));
      await tester.pumpAndSettle();

      expect(siblingNode(tester).hasFocus, isTrue);
      expect(logsScope(tester).hasFocus, isFalse);
    });

    testWidgets('unfocusing search inside the logs pane returns focus to it', (
      tester,
    ) async {
      await pumpSplitView(tester);
      await tester.tap(searchField());
      await tester.pumpAndSettle();

      searchNode(tester).unfocus();
      await tester.pumpAndSettle();

      expect(searchNode(tester).hasFocus, isFalse);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'DesktopLogKeyboard',
      );
    });

    testWidgets('search shortcut is ignored while the sibling pane has focus', (
      tester,
    ) async {
      await pumpSplitView(tester);
      await tester.tap(find.byKey(siblingKey));
      await tester.pumpAndSettle();

      await pressSearchShortcut(tester);

      expect(siblingNode(tester).hasFocus, isTrue);
      expect(searchNode(tester).hasFocus, isFalse);
    });

    testWidgets(
      'search shortcut focuses search while the logs pane is active',
      (tester) async {
        await pumpSplitView(tester);
        logsScope(tester).requestFocus();
        await tester.pumpAndSettle();

        await pressSearchShortcut(tester);

        expect(searchNode(tester).hasFocus, isTrue);
      },
    );
  });

  group('LogsScreen sharing a focus scope with another field', () {
    const neighbourKey = ValueKey('neighbour-field');

    setUp(() {
      ISpect.initialize(
        ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      );
      addTearDown(ISpect.dispose);
    });

    testWidgets('leaving search for the other field keeps focus there', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ISpectScopeController(
          model: ISpectScopeModel(isISpectEnabled: true),
          child: MaterialApp(
            localizationsDelegates: ISpectLocalization.localizationDelegates,
            supportedLocales: ISpectLocalization.supportedLocales,
            home: const Column(
              children: [
                Material(child: TextField(key: neighbourKey)),
                Expanded(child: LogsScreen(options: ISpectOptions())),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byType(LogsScreen),
        matching: find.byType(EditableText),
      );
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(search).focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(neighbourKey));
      await tester.pumpAndSettle();

      final neighbour = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(neighbourKey),
          matching: find.byType(EditableText),
        ),
      );
      expect(neighbour.focusNode.hasFocus, isTrue);
    });
  });

  group('LogsScreen pushed as a route', () {
    setUp(() {
      ISpect.initialize(
        ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      );
      addTearDown(ISpect.dispose);
    });

    Future<void> pushLogsRoute(WidgetTester tester, Size size) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ISpectScopeController(
          model: ISpectScopeModel(isISpectEnabled: true),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: ISpectLocalization.localizationDelegates,
            supportedLocales: ISpectLocalization.supportedLocales,
            home: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      unawaited(
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const LogsScreen(options: ISpectOptions()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pressSearchShortcut(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    FocusNode searchNode(WidgetTester tester) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byType(LogsScreen),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode;

    for (final (label, size) in [
      ('desktop', const Size(1400, 900)),
      ('phone', const Size(390, 844)),
    ]) {
      testWidgets('search shortcut focuses search on a $label route', (
        tester,
      ) async {
        await pushLogsRoute(tester, size);

        await pressSearchShortcut(tester);

        expect(searchNode(tester).hasFocus, isTrue);
      });
    }
  });
}
