import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/app_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/filter_button.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/search_bar.dart';
import 'package:ispectify/ispectify.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('ISpectAppBar', () {
    late ISpectViewController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = ISpectViewController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildAppBar({
      String title = 'ISpect',
      VoidCallback? onShareTap,
      VoidCallback? onMoreTap,
      int? totalCount,
    }) => appShell(
      CustomScrollView(
        slivers: [
          ISpectAppBar(
            title: title,
            controller: controller,
            counts: const {'info': 1, 'error': 1},
            uniqTitles: const ['info', 'error'],
            onToggleTitle: (_, __) {},
            focusNode: focusNode,
            onShareTap: onShareTap,
            onMoreTap: onMoreTap,
            totalCount: totalCount,
          ),
          const SliverFillRemaining(),
        ],
      ),
    );

    testWidgets('Given an ISpectAppBar with title "ISpect", '
        'When it is rendered, '
        'Then the title text is displayed', (tester) async {
      await tester.pumpWidget(buildAppBar());
      await tester.pumpAndSettle();

      expect(find.text('ISpect'), findsOneWidget);
    });

    testWidgets('Given an ISpectAppBar title with or without a log counter, '
        'When it is rendered, '
        'Then the title keeps the compact font size', (tester) async {
      const title = '📅 Current: 21.07.2026';

      await tester.pumpWidget(buildAppBar(title: title));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(title)).style?.fontSize, 18);

      await tester.pumpWidget(buildAppBar(title: title, totalCount: 2937));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(title)).style?.fontSize, 18);
    });

    testWidgets('the title is not announced as a button without a tap action', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppBar(totalCount: 3));
      await tester.pumpAndSettle();

      final titleSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'ISpect',
        ),
      );
      expect(titleSemantics.properties.button, isNot(isTrue));
      expect(titleSemantics.properties.hint, isNull);
    });

    testWidgets('Given an ISpectAppBar, '
        'When it is rendered, '
        'Then a search bar is displayed', (tester) async {
      await tester.pumpWidget(buildAppBar());
      await tester.pumpAndSettle();

      expect(find.byType(ISpectSearchBar), findsOneWidget);
    });

    testWidgets('Given an ISpectAppBar, '
        'When it is rendered, '
        'Then a filter button is displayed', (tester) async {
      await tester.pumpWidget(buildAppBar());
      await tester.pumpAndSettle();

      expect(find.byType(ISpectFilterButton), findsOneWidget);
    });

    testWidgets('Given an ISpectAppBar with a search bar, '
        'When text is entered into the search field, '
        'Then the search controller text updates immediately', (tester) async {
      await tester.pumpWidget(buildAppBar());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'test');
      await tester.pump();

      expect(controller.searchController.text, 'test');

      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('search uses the configured processing debounce once', (
      tester,
    ) async {
      controller.dispose();
      controller = ISpectViewController(
        processingPolicy: DiagnosticProcessingPolicy.balanced.copyWith(
          searchDebounce: const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpWidget(buildAppBar());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'test');
      await tester.pump(const Duration(milliseconds: 99));
      expect(controller.filter.searchQuery, isNot('test'));

      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.filter.searchQuery, 'test');
    });

    testWidgets('the share button runs the share callback in one tap', (
      tester,
    ) async {
      var shareTaps = 0;
      await tester.pumpWidget(buildAppBar(onShareTap: () => shareTaps++));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Share log file'));
      await tester.pump();

      expect(shareTaps, 1);
    });

    testWidgets('the more button runs the menu callback', (tester) async {
      var moreTaps = 0;
      await tester.pumpWidget(buildAppBar(onMoreTap: () => moreTaps++));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options'));
      await tester.pump();

      expect(moreTaps, 1);
    });

    testWidgets('share and more buttons are hidden without callbacks', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppBar());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Share log file'), findsNothing);
      expect(find.byTooltip('More options'), findsNothing);
    });
  });
}
