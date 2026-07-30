import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispectify/ispectify.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('copyClipboard redaction', () {
    late String? clipboardText;

    setUp(() {
      clipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map?)?['text'] as String?;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      ISpectRedaction.reset();
    });

    testWidgets(
      'Given a value containing a Bearer token, '
      'When copyClipboard is called with redact: true, '
      'Then the clipboard contains the masked form',
      (tester) async {
        await tester.pumpWidget(appShell(const SizedBox.shrink()));
        final BuildContext context = tester.element(find.byType(SizedBox));

        copyClipboard(
          context,
          value: 'Authorization: Bearer super-secret-token',
          redact: true,
        );
        await tester.pumpAndSettle();

        expect(clipboardText, isNotNull);
        expect(clipboardText, isNot(contains('super-secret-token')));
        expect(clipboardText, 'Authorization: [REDACTED]');
      },
    );

    testWidgets(
      'Given a JSON string with a "password" field, '
      'When copyClipboard is called with redact: true, '
      'Then the password value is masked',
      (tester) async {
        await tester.pumpWidget(appShell(const SizedBox.shrink()));
        final BuildContext context = tester.element(find.byType(SizedBox));

        copyClipboard(
          context,
          value: '{"user":"alice","password":"p@ss123"}',
          redact: true,
        );
        await tester.pumpAndSettle();

        expect(clipboardText, isNotNull);
        expect(clipboardText, isNot(contains('p@ss123')));
        expect(clipboardText, contains('"password": "[REDACTED]"'));
      },
    );

    testWidgets(
      'Given a URL with embedded credentials, '
      'When copyClipboard is called with redact: true, '
      'Then credentials are masked',
      (tester) async {
        await tester.pumpWidget(appShell(const SizedBox.shrink()));
        final BuildContext context = tester.element(find.byType(SizedBox));

        copyClipboard(
          context,
          value: 'https://alice:secret@api.example.com/v1',
          redact: true,
        );
        await tester.pumpAndSettle();

        expect(clipboardText, isNotNull);
        expect(clipboardText, isNot(contains('alice:secret')));
        expect(clipboardText, contains('://REDACTED@'));
      },
    );

    testWidgets(
      'Given a value and redact: false, '
      'When copyClipboard is called, '
      'Then the value is copied verbatim',
      (tester) async {
        await tester.pumpWidget(appShell(const SizedBox.shrink()));
        final BuildContext context = tester.element(find.byType(SizedBox));

        const raw = 'Authorization: Bearer super-secret-token';
        copyClipboard(context, value: raw);
        await tester.pumpAndSettle();

        expect(clipboardText, raw);
      },
    );

    testWidgets('uses the global custom redaction policy', (tester) async {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'global_field'},
          placeholder: '<global>',
        ),
      );
      await tester.pumpWidget(appShell(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      copyClipboard(
        context,
        value: '{"global_field":"GLOBAL_RAW","safe_field":"VISIBLE"}',
        redact: true,
      );
      await tester.pumpAndSettle();

      expect(clipboardText, contains('<global>'));
      expect(clipboardText, isNot(contains('GLOBAL_RAW')));
      expect(clipboardText, contains('VISIBLE'));
    });

    testWidgets('prefers an explicit service over keys and global policy',
        (tester) async {
      final globalService = RedactionService(
        sensitiveKeys: const {'global_field'},
        placeholder: '<global>',
      );
      final localService = RedactionService(
        sensitiveKeys: const {'local_field'},
        placeholder: '<local>',
      );
      ISpectRedaction.configure(service: globalService);
      await tester.pumpWidget(appShell(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      copyClipboard(
        context,
        value: '{"global_field":"GLOBAL_RAW","local_field":"LOCAL_RAW",'
            '"option_field":"OPTION_RAW"}',
        redact: true,
        redactKeys: const {'option_field'},
        redactionService: localService,
      );
      await tester.pumpAndSettle();

      expect(clipboardText, contains('<local>'));
      expect(clipboardText, isNot(contains('LOCAL_RAW')));
      expect(clipboardText, contains('GLOBAL_RAW'));
      expect(clipboardText, contains('OPTION_RAW'));
      expect(ISpectRedaction.service, same(globalService));
    });

    testWidgets('bounds oversized values before redaction', (tester) async {
      await tester.pumpWidget(appShell(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      final raw = 'password=CLIPBOARD_SECRET${_asciiString(4 * 1024 * 1024)}';

      copyClipboard(context, value: raw, redact: true);
      await tester.pumpAndSettle();

      expect(clipboardText, LogExportOutput.truncatedMarker);
      expect(clipboardText, isNot(contains('CLIPBOARD_SECRET')));
    });

    testWidgets('bounds explicit raw clipboard output by UTF-8 bytes',
        (tester) async {
      await tester.pumpWidget(appShell(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      copyClipboard(
        context,
        value: _asciiString(4 * 1024 * 1024),
      );
      await tester.pumpAndSettle();

      expect(
        LogExportOutput.utf8Length(clipboardText!),
        lessThanOrEqualTo(100000),
      );
      expect(clipboardText, endsWith(LogExportOutput.truncatedMarker));
    });

    testWidgets('honors a local clipboard byte budget', (tester) async {
      await tester.pumpWidget(appShell(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      copyClipboard(
        context,
        value: _asciiString(1024),
        resourceLimits: DiagnosticResourceLimits.balanced.copyWith(
          maxClipboardBytes: 64,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        LogExportOutput.utf8Length(clipboardText!),
        lessThanOrEqualTo(64),
      );
      expect(clipboardText, endsWith(LogExportOutput.truncatedMarker));
    });
  });
}

String _asciiString(int length) =>
    String.fromCharCodes(Uint8List(length)..fillRange(0, length, 97));
