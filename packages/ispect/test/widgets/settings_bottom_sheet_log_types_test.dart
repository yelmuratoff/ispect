import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/settings_bottom_sheet.dart';

import '../helpers/pump_ispect.dart';

void main() {
  const initialSettings = ISpectSettingsState(
    enabled: true,
    useConsoleLogs: false,
    useHistory: true,
  );

  late ISpectLogger loggerValue;
  late ISpectLoggerNotifier logger;
  late ISpectViewController controller;
  late List<ISpectSettingsState> persisted;

  setUp(() {
    loggerValue = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    logger = ISpectLoggerNotifier(loggerValue);
    persisted = [];
    controller = ISpectViewController(
      initialSettings: initialSettings,
      onSettingsChanged: persisted.add,
    );
    addTearDown(() {
      controller.dispose();
      logger.dispose();
      loggerValue.dispose();
    });
  });

  Future<void> pumpShell(WidgetTester tester) async {
    final sheet = ISpectSettingsBottomSheet(
      logger: logger,
      actions: const [],
      controller: controller,
    );

    await tester.pumpWidget(
      appShell(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(sheet.show(context)),
            child: const Text('Open settings'),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
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

  Set<String?> capturedKeys() => loggerValue.history.map((e) => e.key).toSet();

  testWidgets('a disabled log type survives closing and reopening the sheet',
      (tester) async {
    await pumpShell(tester);
    await openSheet(tester);
    await tapInSheet(tester, 'Riverpod Add');

    expect(controller.settings.disabledLogTypes, contains('riverpod-add'));

    await closeSheet(tester);
    await openSheet(tester);

    expect(controller.settings.disabledLogTypes, contains('riverpod-add'));
    expect(
      persisted.last.disabledLogTypes,
      contains('riverpod-add'),
      reason: 'the host must not be handed back the startup snapshot',
    );

    loggerValue.logData(ISpectLogData('added', key: 'riverpod-add'));
    expect(capturedKeys(), isNot(contains('riverpod-add')));
  });

  testWidgets('re-enabling every type lets the disabled logs through again',
      (tester) async {
    await pumpShell(tester);
    await openSheet(tester);
    await tapInSheet(tester, 'Riverpod Add');
    await tapInSheet(tester, 'Select All');

    expect(controller.settings.disabledLogTypes, isEmpty);

    loggerValue.logData(ISpectLogData('added', key: 'riverpod-add'));
    expect(capturedKeys(), contains('riverpod-add'));
  });

  testWidgets('deselecting all types blocks every displayed log type',
      (tester) async {
    await pumpShell(tester);
    await openSheet(tester);
    await tapInSheet(tester, 'Deselect All');

    expect(
      controller.settings.disabledLogTypes,
      containsAll(<String>['riverpod-add', 'http-request', 'info']),
    );

    loggerValue
      ..logData(ISpectLogData('added', key: 'riverpod-add'))
      ..logData(ISpectLogData('request', key: 'http-request'));
    expect(loggerValue.history, isEmpty);
  });
}
