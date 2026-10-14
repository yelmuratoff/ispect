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
        onClearAllFilters: controller.clearAllFilters,
      ),
    );

    bool? isChipToggled(WidgetTester tester, String key) => tester
        .widget<Semantics>(
          find.ancestor(
            of: find.text('1  $key'),
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
      await tester.tap(find.text('1  error'));
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
      await tester.tap(find.text('1  error'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(sheet(const ['error', 'info']));
      await tester.pumpAndSettle();

      expect(controller.filter.logTypeKeys, {'error'});
      expect(isChipToggled(tester, 'error'), isTrue);
      expect(isChipToggled(tester, 'info'), isFalse);
    });
  });
}
