import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/filter_sheet.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('ISpectFilterSheet chips', () {
    late ISpectViewController controller;

    setUp(() {
      controller = ISpectViewController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget sheet(List<String> uniqTitles) => appShell(
      ISpectFilterSheet(
        controller: controller,
        counts: const {'info': 1, 'error': 1},
        uniqTitles: uniqTitles,
        onToggleTitle: (key, selected) =>
            controller.handleLogTypeKeyFilterToggle(key, isSelected: selected),
        onClearAllFilters: controller.clearSearchAndFilters,
      ),
    );

    bool? isChipToggled(WidgetTester tester, String key) => tester
        .widget<Semantics>(
          find.descendant(
            of: find.byKey(ValueKey('log-type-chip-$key')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.toggled != null,
            ),
          ),
        )
        .properties
        .toggled;

    testWidgets('switching to highlight mode shows every chip unselected', (
      tester,
    ) async {
      controller.searchMode = SearchMode.filter;
      await tester.pumpWidget(sheet(const ['info', 'error']));
      await tester.tap(find.byKey(const ValueKey('log-type-chip-error')));
      await tester.pumpAndSettle();
      expect(isChipToggled(tester, 'error'), isTrue);

      controller.searchMode = SearchMode.highlight;
      await tester.pumpAndSettle();

      expect(controller.filter.logTypeKeys, isEmpty);
      expect(isChipToggled(tester, 'error'), isFalse);
    });

    testWidgets('a selected chip follows its key when the key order changes', (
      tester,
    ) async {
      await tester.pumpWidget(sheet(const ['info', 'error']));
      await tester.tap(find.byKey(const ValueKey('log-type-chip-error')));
      await tester.pumpAndSettle();

      await tester.pumpWidget(sheet(const ['error', 'info']));
      await tester.pumpAndSettle();

      expect(controller.filter.logTypeKeys, {'error'});
      expect(isChipToggled(tester, 'error'), isTrue);
      expect(isChipToggled(tester, 'info'), isFalse);
    });

    testWidgets('a chip shows the log type title, not its raw key', (
      tester,
    ) async {
      await tester.pumpWidget(sheet(const ['http-request']));
      await tester.pumpAndSettle();

      final chip = find.byKey(const ValueKey('log-type-chip-http-request'));
      expect(
        find.descendant(
          of: chip,
          matching: find.textContaining('HTTP Request'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: chip,
          matching: find.textContaining('http-request'),
        ),
        findsNothing,
      );
    });

    testWidgets('offers clear all for a hide-others search without chips', (
      tester,
    ) async {
      controller
        ..searchMode = SearchMode.filter
        ..searchByCorrelationId('timeout');
      await tester.pumpWidget(sheet(const ['info']));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();

      expect(controller.hasClearableFilters, isFalse);
      expect(controller.searchController.text, isEmpty);
    });

    testWidgets('hides clear all when nothing narrows the list', (
      tester,
    ) async {
      controller
        ..searchMode = SearchMode.highlight
        ..searchByCorrelationId('timeout');
      await tester.pumpWidget(sheet(const ['info']));
      await tester.pumpAndSettle();

      expect(find.text('Clear all filters'), findsNothing);
    });

    testWidgets('a chip announces its title and count once', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(sheet(const ['info']));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Info (1)'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the search mode names what happens to the list', (
      tester,
    ) async {
      await tester.pumpWidget(sheet(const ['info']));
      await tester.pumpAndSettle();

      expect(find.text('Highlight'), findsOneWidget);
      expect(find.text('Hide others'), findsOneWidget);

      await tester.tap(find.text('Hide others'));
      await tester.pumpAndSettle();

      expect(controller.searchMode, SearchMode.filter);
    });
  });
}
