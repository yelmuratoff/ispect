import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/app_bar.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/filter_button.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/app_bar/search_bar.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('ISpectAppBar', () {
    late ISpectViewController controller;
    late GroupButtonController titlesController;
    late FocusNode focusNode;

    setUp(() {
      controller = ISpectViewController();
      titlesController = GroupButtonController();
      focusNode = FocusNode();
    });

    tearDown(() {
      focusNode.dispose();
      titlesController.dispose();
    });

    Widget buildAppBar({
      String title = 'ISpect',
      VoidCallback? onSettingsTap,
      int? filteredCount,
      int? totalCount,
    }) =>
        appShell(
          CustomScrollView(
            slivers: [
              ISpectAppBar(
                title: title,
                titlesController: titlesController,
                controller: controller,
                titles: const ['info', 'error'],
                uniqTitles: const ['info', 'error'],
                onToggleTitle: (_, __) {},
                focusNode: focusNode,
                onSettingsTap: onSettingsTap,
                filteredCount: filteredCount,
                totalCount: totalCount,
              ),
              const SliverFillRemaining(),
            ],
          ),
        );

    testWidgets(
      'Given an ISpectAppBar with title "ISpect", '
      'When it is rendered, '
      'Then the title text is displayed',
      (tester) async {
        await tester.pumpWidget(buildAppBar());
        await tester.pumpAndSettle();

        expect(find.text('ISpect'), findsOneWidget);
      },
    );

    testWidgets(
      'Given an ISpectAppBar, '
      'When it is rendered, '
      'Then a search bar is displayed',
      (tester) async {
        await tester.pumpWidget(buildAppBar());
        await tester.pumpAndSettle();

        expect(find.byType(ISpectSearchBar), findsOneWidget);
      },
    );

    testWidgets(
      'Given an ISpectAppBar, '
      'When it is rendered, '
      'Then a filter button is displayed',
      (tester) async {
        await tester.pumpWidget(buildAppBar());
        await tester.pumpAndSettle();

        expect(find.byType(ISpectFilterButton), findsOneWidget);
      },
    );

    testWidgets(
      'Given an ISpectAppBar with a search bar, '
      'When text is entered into the search field, '
      'Then the search controller text updates immediately',
      (tester) async {
        await tester.pumpWidget(buildAppBar());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(SearchBar), 'test');
        await tester.pump();

        expect(controller.searchController.text, 'test');

        // Settle all internal debounce timers.
        await tester.pumpAndSettle(const Duration(seconds: 1));
      },
    );

    testWidgets(
      'Given an onSettingsTap callback is provided, '
      'When the app bar is rendered, '
      'Then the settings button appears',
      (tester) async {
        await tester.pumpWidget(
          buildAppBar(onSettingsTap: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Given no onSettingsTap callback, '
      'When the app bar is rendered, '
      'Then the settings button is hidden',
      (tester) async {
        await tester.pumpWidget(buildAppBar());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings_outlined), findsNothing);
      },
    );
  });
}
