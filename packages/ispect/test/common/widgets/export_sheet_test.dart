import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_en.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations_ru.dart';

import '../../helpers/pump_ispect.dart';

void main() {
  final en = ISpectGeneratedLocalizationEn();

  late String? clipboardText;
  late bool clipboardFails;

  setUp(() {
    clipboardText = null;
    clipboardFails = false;
    ISpect.initialize(
      ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      force: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            if (clipboardFails) {
              throw PlatformException(code: 'clipboard-unavailable');
            }
            clipboardText = (call.arguments as Map?)?['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await ISpect.dispose();
  });

  Future<void> openAndCopy(
    WidgetTester tester,
    ExportContentBuilder contentBuilder, {
    Locale? locale,
  }) async {
    final controller = ExportController(
      availableFormats: const [ExportFormat.text],
      feedbackDuration: Duration.zero,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      appShell(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ISpectExportSheet.show(
              context,
              controller: controller,
              contentBuilder: contentBuilder,
            ),
            child: const Text('open'),
          ),
        ),
        locale: locale,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('copies the built content after the sheet closes', (
    tester,
  ) async {
    await openAndCopy(
      tester,
      (_, {required action, redactKeys}) async => 'exported-body',
    );

    expect(clipboardText, 'exported-body');
    expect(find.textContaining(en.logItemCopied), findsOneWidget);
  });

  testWidgets('shows an error instead of a copied toast when building fails', (
    tester,
  ) async {
    await openAndCopy(
      tester,
      (_, {required action, redactKeys}) async =>
          throw StateError('builder failed'),
    );

    expect(clipboardText, isNull);
    expect(find.textContaining(en.logItemCopied), findsNothing);
    expect(find.text(en.copyToClipboardFailed), findsOneWidget);
  });

  testWidgets('shows an error instead of a copied toast when the clipboard '
      'write fails', (tester) async {
    clipboardFails = true;
    await openAndCopy(
      tester,
      (_, {required action, redactKeys}) async => 'exported-body',
    );

    expect(find.textContaining(en.logItemCopied), findsNothing);
    expect(find.text(en.copyToClipboardFailed), findsOneWidget);
  });

  testWidgets('reports a failed copy in the active locale', (tester) async {
    await openAndCopy(
      tester,
      (_, {required action, redactKeys}) async =>
          throw StateError('builder failed'),
      locale: const Locale('ru'),
    );

    expect(
      find.text(ISpectGeneratedLocalizationRu().copyToClipboardFailed),
      findsOneWidget,
    );
  });
}
