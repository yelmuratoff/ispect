import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_en.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_ru.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';

void main() {
  late ISpectLogger logger;

  setUp(() {
    logger = ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));
    ISpect.initialize(logger);
    addTearDown(ISpect.dispose);
  });

  Future<void> openSettingsSheet(
    WidgetTester tester, {
    ISpectOptions? options,
    Locale? locale,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 3200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ISpectScopeController(
        model: ISpectScopeModel(isISpectEnabled: true),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: LogsScreen(options: options ?? const ISpectOptions()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();
  }

  testWidgets('offers reverse, group and expand only as display toggles', (
    tester,
  ) async {
    await openSettingsSheet(tester);
    final l10n = ISpectGeneratedLocalizationEn();

    expect(find.text(l10n.shareLogsFile), findsOneWidget);
    expect(find.text(l10n.reverseLogs), findsOneWidget);
    expect(find.text(l10n.groupHttpLogs), findsOneWidget);
    expect(find.text(l10n.expandLogs), findsOneWidget);
    expect(find.text(l10n.reverseLogsDesc), findsNothing);
    expect(find.text(l10n.ungroupHttpLogs), findsNothing);
    expect(find.text(l10n.ungroupHttpLogsDesc), findsNothing);
    expect(find.text(l10n.expandLogsDesc), findsNothing);
  });

  group('log viewer import', () {
    testWidgets('opens pasted JSON in the JSON viewer', (tester) async {
      await openSettingsSheet(tester);
      final l10n = ISpectGeneratedLocalizationEn();

      await tester.tap(find.text(l10n.logViewer).last);
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
      await openSettingsSheet(
        tester,
        locale: const Locale('ru'),
        options: ISpectOptions(onLoadLogContent: (_) async => '   '),
      );
      final l10n = ISpectGeneratedLocalizationRu();

      await tester.tap(find.text(l10n.logViewer).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.loadFileContent).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.contentProcessingError), findsOneWidget);
      expect(find.text(l10n.contentEmptyError), findsOneWidget);
      expect(find.byType(JsonScreen), findsNothing);
    });
  });
}
