// Composition test for the settings sheet reached the way the app reaches it:
// LogsScreen bootstraps its controller from the live scope, and the sheet is
// handed `ISpectOptions.initialSettings` — the startup seed that must never
// be replayed over the user's live choices.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';

void main() {
  const seed = ISpectSettingsState(
    enabled: true,
    useConsoleLogs: false,
    useHistory: true,
  );

  late ISpectLogger logger;
  late ISpectScopeModel scope;
  late List<ISpectSettingsState> persisted;

  setUp(() {
    logger = ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));
    ISpect.initialize(logger);
    scope = ISpectScopeModel(isISpectEnabled: true)..settings = seed;
    persisted = [];
    addTearDown(() async {
      await ISpect.dispose();
    });
  });

  Future<void> pumpLogsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ISpectScopeController(
        model: scope,
        child: MaterialApp(
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: LogsScreen(
            options: ISpectOptions(
              initialSettings: seed,
              onSettingsChanged: persisted.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();
  }

  Future<void> closeSettings(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
  }

  Future<void> tapInSheet(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      250,
      scrollable: find.byType(Scrollable, skipOffstage: false).last,
    );
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('a log type disabled through the real screen stays disabled',
      (tester) async {
    await pumpLogsScreen(tester);
    await openSettings(tester);
    await tapInSheet(tester, 'Riverpod Add');
    await closeSettings(tester);

    expect(scope.settings.disabledLogTypes, contains('riverpod-add'));
    expect(persisted.last.disabledLogTypes, contains('riverpod-add'));

    await openSettings(tester);

    expect(
      scope.settings.disabledLogTypes,
      contains('riverpod-add'),
      reason: 'reopening the sheet must not replay the startup seed',
    );
    expect(persisted.last.disabledLogTypes, contains('riverpod-add'));

    await closeSettings(tester);

    logger.logData(ISpectLogData('added', key: 'riverpod-add'));
    expect(
      logger.history.map((e) => e.key),
      isNot(contains('riverpod-add')),
    );
  });

  testWidgets('the scope keeps the disabled set after the sheet closes',
      (tester) async {
    await pumpLogsScreen(tester);
    await openSettings(tester);
    await tapInSheet(tester, 'Deselect All');
    await closeSettings(tester);

    expect(
      scope.settings.disabledLogTypes,
      containsAll(<String>['riverpod-add', 'http-request', 'info']),
    );

    await openSettings(tester);

    expect(
      scope.settings.disabledLogTypes,
      containsAll(<String>['riverpod-add', 'http-request', 'info']),
    );
  });
}
