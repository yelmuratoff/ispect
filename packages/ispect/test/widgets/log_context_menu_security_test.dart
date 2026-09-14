import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_context_menu.dart';

import '../helpers/hostile_export_diagnostics.dart';
import '../helpers/pump_ispect.dart';

void main() {
  testWidgets('context-menu copy safely minimizes hostile values', (
    tester,
  ) async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map?)?['text'] as String?;
          }
          return null;
        });
    addTearDown(() {
      ISpectRedaction.enabled = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    const secret = 'CONTEXT_MENU_COPY_SECRET';
    final hostile = hostileCopyLog(secret);
    final exceptionCallsAtCapture = hostile.exception.calls;
    final errorCallsAtCapture = hostile.error.calls;
    final stackCallsAtCapture = hostile.stackTrace.calls;
    await tester.pumpWidget(
      appShell(const SizedBox(key: Key('context-menu-anchor'))),
    );
    final context = tester.element(
      find.byKey(const Key('context-menu-anchor')),
    );

    final menu = showLogContextMenu(
      context: context,
      position: Offset.zero,
      data: hostile.log,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.content_copy_rounded));
    await tester.pumpAndSettle();
    await menu;

    expect(clipboardText, isNotNull);
    expect(utf8.encode(clipboardText!).length, lessThanOrEqualTo(100000));
    expect(clipboardText, contains(JsonValueNormalizer.unprintableValue));
    expect(clipboardText, isNot(contains(secret)));
    expect(hostile.exception.calls, exceptionCallsAtCapture);
    expect(hostile.error.calls, errorCallsAtCapture);
    expect(hostile.stackTrace.calls, stackCallsAtCapture);
  });
}
