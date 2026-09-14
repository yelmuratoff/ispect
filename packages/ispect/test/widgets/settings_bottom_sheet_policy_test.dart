import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/settings_bottom_sheet.dart';

import '../helpers/pump_ispect.dart';

void main() {
  testWidgets('policy profiles update settings, viewer, and logger', (
    tester,
  ) async {
    final loggerValue = ISpectLogger.testing(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final logger = ISpectLoggerNotifier(loggerValue);
    final controller = ISpectViewController();
    addTearDown(() {
      controller.dispose();
      logger.dispose();
      loggerValue.dispose();
    });
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
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Resource profile'),
      250,
      scrollable: find.byType(Scrollable, skipOffstage: false).last,
    );
    await tester.ensureVisible(find.text('Resource profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resource profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Constrained').last);
    await tester.pumpAndSettle();

    expect(
      controller.settings.resourceLimits,
      DiagnosticResourceLimits.constrained,
    );
    expect(controller.resourceLimits, DiagnosticResourceLimits.constrained);
    expect(
      loggerValue.options.resourceLimits,
      DiagnosticResourceLimits.constrained,
    );

    await tester.scrollUntilVisible(
      find.text('Processing profile'),
      200,
      scrollable: find.byType(Scrollable, skipOffstage: false).last,
    );
    await tester.ensureVisible(find.text('Processing profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Processing profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsive').last);
    await tester.pumpAndSettle();

    expect(
      controller.settings.processingPolicy,
      DiagnosticProcessingPolicy.responsive,
    );
    expect(controller.processingPolicy, DiagnosticProcessingPolicy.responsive);
    expect(
      loggerValue.options.processingPolicy,
      DiagnosticProcessingPolicy.responsive,
    );

    await tester.scrollUntilVisible(
      find.text('Capture mode'),
      200,
      scrollable: find.byType(Scrollable, skipOffstage: false).last,
    );
    await tester.ensureVisible(find.text('Capture mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strict').last);
    await tester.pumpAndSettle();

    expect(controller.settings.captureMode, DiagnosticCaptureMode.strict);
    expect(loggerValue.options.captureMode, DiagnosticCaptureMode.strict);
  });
}
