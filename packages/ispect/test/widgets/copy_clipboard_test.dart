import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';

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
        expect(clipboardText, contains('Bearer ***'));
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
        expect(clipboardText, contains('"password": "***"'));
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
        expect(clipboardText, contains('://***:***@'));
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
  });
}
