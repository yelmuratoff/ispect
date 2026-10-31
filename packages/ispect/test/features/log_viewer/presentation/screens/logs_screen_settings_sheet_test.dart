import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_en.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_ru.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';

void main() {
  late ISpectLogger logger;

  setUp(() {
    logger = ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));
    ISpect.initialize(logger);
    addTearDown(ISpect.dispose);
  });

  Future<void> pumpLogsScreen(
    WidgetTester tester, {
    ISpectOptions? options,
    ISpectViewController? controller,
    ISpectSettingsState? settings,
    Locale? locale,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 3200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final model = ISpectScopeModel(isISpectEnabled: true);
    if (settings != null) model.settings = settings;
    await tester.pumpWidget(
      ISpectScopeController(
        model: model,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: LogsScreen(
            options: options ?? const ISpectOptions(),
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(
    WidgetTester tester, {
    ISpectOptions? options,
    Locale? locale,
  }) async {
    await pumpLogsScreen(tester, options: options, locale: locale);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
  }

  group('without a host share callback', () {
    testWidgets('the app bar export button opens the export sheet with the '
        'log count', (tester) async {
      await pumpLogsScreen(tester);
      final l10n = ISpectGeneratedLocalizationEn();

      await tester.tap(find.byTooltip(l10n.exportLogs));
      await tester.pumpAndSettle();

      final sheet = find.byType(ISpectExportSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text(l10n.export)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(l10n.logCount(logger.history.length)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the menu names the action Export logs', (tester) async {
      await openMenu(tester);
      final l10n = ISpectGeneratedLocalizationEn();

      expect(find.text(l10n.exportLogs), findsOneWidget);
      expect(find.text(l10n.exportLogsDesc), findsOneWidget);
      expect(find.text(l10n.shareLogsFile), findsNothing);
    });
  });

  testWidgets('with a host share callback every entry point says Share', (
    tester,
  ) async {
    await pumpLogsScreen(tester, options: ISpectOptions(onShare: (_) async {}));
    final l10n = ISpectGeneratedLocalizationEn();

    expect(find.byTooltip(l10n.shareLogsFile), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.shareLogsFile), findsOneWidget);
    expect(find.text(l10n.shareLogsFileDesc), findsOneWidget);
    expect(find.text(l10n.exportLogs), findsNothing);
  });

  testWidgets('the menu leads with actions and leaves display options out', (
    tester,
  ) async {
    await openMenu(tester);
    final l10n = ISpectGeneratedLocalizationEn();

    expect(find.text(l10n.importLogs), findsOneWidget);
    expect(find.text(l10n.clearHistory), findsOneWidget);
    expect(find.text(l10n.reverseLogs), findsNothing);
    expect(find.text(l10n.groupHttpLogs), findsNothing);
    expect(find.text(l10n.expandLogs), findsNothing);
  });

  testWidgets('the menu cannot hide the panel button that opens it', (
    tester,
  ) async {
    await openMenu(tester);
    final l10n = ISpectGeneratedLocalizationEn();

    expect(find.text(l10n.panelButtons.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.performance), findsOneWidget);
    expect(find.text(l10n.logViewer), findsNothing);
    expect(find.text(l10n.logs), findsNothing);
    expect(find.byIcon(Icons.reorder_rounded), findsNothing);
  });

  group('clear history', () {
    testWidgets('cancelling the confirmation keeps every log', (tester) async {
      logger.info('kept entry');
      await openMenu(tester);
      final l10n = ISpectGeneratedLocalizationEn();

      await tester.tap(find.text(l10n.clearHistory));
      await tester.pumpAndSettle();

      expect(find.text(l10n.clearHistoryConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(logger.history.map((e) => e.message), contains('kept entry'));
    });

    testWidgets('confirming removes the history', (tester) async {
      logger.info('removed entry');
      await openMenu(tester);
      final l10n = ISpectGeneratedLocalizationEn();

      await tester.tap(find.text(l10n.clearHistory));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.clearHistory).last);
      await tester.pumpAndSettle();

      expect(logger.history, isEmpty);
    });
  });

  testWidgets('the menu keeps expert limits collapsed until asked', (
    tester,
  ) async {
    await openMenu(tester);
    final l10n = ISpectGeneratedLocalizationEn();

    expect(find.text(l10n.resourceProfile), findsNothing);

    await tester.tap(find.text(l10n.settingsAdvanced));
    await tester.pumpAndSettle();

    expect(find.text(l10n.resourceProfile), findsOneWidget);
    expect(find.text(l10n.historyCapacity), findsOneWidget);
  });

  testWidgets('the filter sheet flips the log order and persists it', (
    tester,
  ) async {
    final persisted = <ISpectSettingsState>[];
    final controller = ISpectViewController(onSettingsChanged: persisted.add);
    addTearDown(controller.dispose);
    await pumpLogsScreen(tester, controller: controller);
    final l10n = ISpectGeneratedLocalizationEn();
    final wasReversed = controller.isLogOrderReversed;

    await tester.tap(find.byTooltip(l10n.filters));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reverseLogs));
    await tester.pumpAndSettle();

    expect(controller.isLogOrderReversed, !wasReversed);
    expect(persisted.last.isLogOrderReversed, !wasReversed);
  });

  testWidgets('a filtering search with no matches offers to clear it', (
    tester,
  ) async {
    logger.info('visible entry');
    final controller = ISpectViewController()..searchMode = SearchMode.filter;
    addTearDown(controller.dispose);
    await pumpLogsScreen(tester, controller: controller);
    final l10n = ISpectGeneratedLocalizationEn();

    await tester.enterText(find.byType(SearchBar), 'zzz-no-such-log');
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(l10n.noMatchingLogs), findsOneWidget);

    await tester.tap(find.text(l10n.clearAllFilters));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(l10n.noMatchingLogs), findsNothing);
    expect(controller.searchController.text, isEmpty);
  });

  testWidgets('types hidden by the recording settings do not offer a '
      'filter reset that cannot help', (tester) async {
    logger.info('hidden by recording settings');
    const settings = ISpectSettingsState(
      enabled: true,
      useConsoleLogs: false,
      useHistory: true,
      disabledLogTypes: {'info'},
    );
    await pumpLogsScreen(
      tester,
      options: const ISpectOptions(initialSettings: settings),
      settings: settings,
    );
    final l10n = ISpectGeneratedLocalizationEn();

    expect(find.text(l10n.noMatchingLogs), findsNothing);
    expect(find.text(l10n.clearAllFilters), findsNothing);
    expect(find.text(l10n.noLogsYet), findsOneWidget);
  });

  group('import logs', () {
    testWidgets('opens pasted JSON in the JSON viewer', (tester) async {
      await openMenu(tester);
      final l10n = ISpectGeneratedLocalizationEn();

      await tester.tap(find.text(l10n.importLogs).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '[{"a":1},{"b":2}]');
      await tester.pump();
      await tester.tap(find.text(l10n.process));
      await tester.pumpAndSettle();

      final screen = tester.widget<JsonScreen>(find.byType(JsonScreen));
      expect(screen.data['data'], hasLength(2));
    });

    testWidgets('reports empty loaded content in the active locale', (
      tester,
    ) async {
      await openMenu(
        tester,
        locale: const Locale('ru'),
        options: ISpectOptions(onLoadLogContent: (_) async => '   '),
      );
      final l10n = ISpectGeneratedLocalizationRu();

      await tester.tap(find.text(l10n.importLogs).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.loadFileContent).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.contentProcessingError), findsOneWidget);
      expect(find.text(l10n.contentEmptyError), findsOneWidget);
      expect(find.byType(JsonScreen), findsNothing);
    });
  });
}
