import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_screen_controller.dart';

import '../helpers/hostile_export_diagnostics.dart';
import '../helpers/pump_ispect.dart';

void main() {
  testWidgets(
    'Cmd/Ctrl+C retains binary provenance until clipboard redaction',
    (tester) async {
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardText = (call.arguments as Map?)?['text'] as String?;
            }
            return null;
          });

      final viewController = ISpectViewController();
      final scrollController = ScrollController();
      final searchFocusNode = FocusNode();
      final titleFiltersController = GroupButtonController();
      final controller = LogsScreenController(
        logsViewController: viewController,
        logsScrollController: scrollController,
        searchFocusNode: searchFocusNode,
        titleFiltersController: titleFiltersController,
        onStateChanged: () {},
      );
      addTearDown(() {
        ISpectRedaction.enabled = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        controller.dispose();
        titleFiltersController.dispose();
        searchFocusNode.dispose();
        scrollController.dispose();
        viewController.dispose();
      });

      ISpectRedaction.enabled = false;
      final log = ISpectLogData(Uint8List.fromList(List<int>.filled(64, 211)));
      ISpectRedaction.enabled = true;
      viewController.activeData = log;

      await tester.pumpWidget(appShell(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final result = controller.handleKeyEvent(
        controller.keyboardFocusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyC,
          logicalKey: LogicalKeyboardKey.keyC,
          timeStamp: Duration.zero,
        ),
        [log],
        context,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(result, KeyEventResult.handled);
      expect(clipboardText, isNotNull);
      expect(clipboardText, isNot(contains('211, 211, 211')));
      expect(clipboardText, '[binary 64 bytes]');
    },
  );

  testWidgets('Cmd/Ctrl+C safely minimizes hostile values', (tester) async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map?)?['text'] as String?;
          }
          return null;
        });

    final viewController = ISpectViewController();
    final scrollController = ScrollController();
    final searchFocusNode = FocusNode();
    final titleFiltersController = GroupButtonController();
    final controller = LogsScreenController(
      logsViewController: viewController,
      logsScrollController: scrollController,
      searchFocusNode: searchFocusNode,
      titleFiltersController: titleFiltersController,
      onStateChanged: () {},
    );
    addTearDown(() {
      ISpectRedaction.enabled = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      controller.dispose();
      titleFiltersController.dispose();
      searchFocusNode.dispose();
      scrollController.dispose();
      viewController.dispose();
    });

    const secret = 'KEYBOARD_COPY_SECRET';
    final hostile = hostileCopyLog(secret);
    final exceptionCallsAtCapture = hostile.exception.calls;
    final errorCallsAtCapture = hostile.error.calls;
    final stackCallsAtCapture = hostile.stackTrace.calls;
    viewController.activeData = hostile.log;

    await tester.pumpWidget(
      appShell(const SizedBox(key: Key('keyboard-copy-anchor'))),
    );
    final context = tester.element(
      find.byKey(const Key('keyboard-copy-anchor')),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final result = controller.handleKeyEvent(
      controller.keyboardFocusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyC,
        logicalKey: LogicalKeyboardKey.keyC,
        timeStamp: Duration.zero,
      ),
      [hostile.log],
      context,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(result, KeyEventResult.handled);
    expect(clipboardText, isNotNull);
    expect(utf8.encode(clipboardText!).length, lessThanOrEqualTo(100000));
    expect(clipboardText, contains(JsonValueNormalizer.unprintableValue));
    expect(clipboardText, isNot(contains(secret)));
    expect(hostile.exception.calls, exceptionCallsAtCapture);
    expect(hostile.error.calls, errorCallsAtCapture);
    expect(hostile.stackTrace.calls, stackCallsAtCapture);
  });
}
