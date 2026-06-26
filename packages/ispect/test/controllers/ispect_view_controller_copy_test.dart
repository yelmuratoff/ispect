import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

void main() {
  group('ISpectViewController clipboard redaction (L2)', () {
    late ISpectViewController controller;

    setUp(() => controller = ISpectViewController());
    tearDown(() => controller.dispose());

    ISpectLogData secretLog() => ISpectLogData(
          'user action',
          key: 'info',
          additionalData: const {
            'password': 'hunter2',
            'userMeta': {'token': 'super-secret-token'},
          },
        );

    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return ctx;
    }

    testWidgets('copyLogEntryText masks nested additionalData secrets',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String captured;

      controller.copyLogEntryText(
        ctx,
        secretLog(),
        (_, {required value}) => captured = value,
      );

      expect(captured, isNot(contains('hunter2')));
      expect(captured, isNot(contains('super-secret-token')));
      expect(captured, contains('[REDACTED]'));
    });

    testWidgets('copyAllLogsToClipboard masks nested additionalData secrets',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String captured;

      controller.copyAllLogsToClipboard(
        ctx,
        [secretLog()],
        (_, {required value, title, showValue}) => captured = value,
        'All logs',
      );

      expect(captured, isNot(contains('hunter2')));
      expect(captured, isNot(contains('super-secret-token')));
      expect(captured, contains('[REDACTED]'));
    });
  });
}
