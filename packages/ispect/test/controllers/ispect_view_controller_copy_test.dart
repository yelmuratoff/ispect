import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

void main() {
  group('ISpectViewController clipboard redaction (L2)', () {
    late ISpectViewController controller;

    setUp(() => controller = ISpectViewController());
    tearDown(() {
      ISpectRedaction.enabled = true;
      controller.dispose();
    });

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

    testWidgets('copyLogEntryText scrubs secrets in free-form messages',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String captured;

      controller.copyLogEntryText(
        ctx,
        ISpectLogData(
          'failed https://alice:password@example.test/users?token=COPY_SECRET',
        ),
        (_, {required value}) => captured = value,
      );

      expect(captured, isNot(contains('alice:password')));
      expect(captured, isNot(contains('COPY_SECRET')));
      expect(captured, contains('[REDACTED]'));
    });

    testWidgets('copyAllLogsToClipboard scrubs free-form messages',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String captured;

      controller.copyAllLogsToClipboard(
        ctx,
        [
          ISpectLogData(
            'failed https://example.test/users?token=COPY_ALL_SECRET',
          ),
        ],
        (_, {required value, title, showValue}) => captured = value,
        'All logs',
      );

      expect(captured, isNot(contains('COPY_ALL_SECRET')));
      expect(captured, contains('[REDACTED]'));
    });

    testWidgets('clipboard exports redact every typed binary container',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String capturedSingle;
      late String capturedAll;
      final log = ISpectLogData(
        'binary',
        additionalData: {
          'bytes': Uint8List.fromList(List<int>.filled(64, 211)),
          'words': Uint16List.fromList(List<int>.filled(32, 60000)),
          'buffer': Uint8List.fromList(List<int>.filled(64, 244)).buffer,
        },
      );

      controller
        ..copyLogEntryText(
          ctx,
          log,
          (_, {required value}) => capturedSingle = value,
        )
        ..copyAllLogsToClipboard(
          ctx,
          [log],
          (_, {required value, title, showValue}) => capturedAll = value,
          'All logs',
        );

      for (final output in [capturedSingle, capturedAll]) {
        expect(output, isNot(contains('211, 211, 211')));
        expect(output, isNot(contains('60000')));
        expect(output, isNot(contains('244, 244, 244')));
        expect(output, contains('[91,98,105,110,97,114,121'));
      }
    });

    testWidgets('clipboard exports never execute caller diagnostic methods',
        (tester) async {
      final ctx = await pumpContext(tester);
      final calls = _InvocationCounters();
      late String capturedSingle;
      late String capturedAll;
      final log = ISpectLogData(
        'safe message',
        exception: _HostileException(calls),
        error: _HostileError(calls),
        stackTrace: _HostileStackTrace(calls),
        additionalData: {'custom': _HostileAdditionalValue(calls)},
      );

      controller
        ..copyLogEntryText(
          ctx,
          log,
          (_, {required value}) => capturedSingle = value,
        )
        ..copyAllLogsToClipboard(
          ctx,
          [log],
          (_, {required value, title, showValue}) => capturedAll = value,
          'All logs',
        );

      expect(calls.toJsonCalls, 0);
      expect(calls.toStringCalls, 0);
      for (final output in [capturedSingle, capturedAll]) {
        expect(output, contains(JsonValueNormalizer.unprintableValue));
        expect(output, isNot(contains('CALLER_TO_JSON_SECRET')));
        expect(output, isNot(contains('CALLER_TO_STRING_SECRET')));
        expect(output, isNot(contains('HOSTILE_EXCEPTION_SECRET')));
        expect(output, isNot(contains('HOSTILE_ERROR_SECRET')));
        expect(output, isNot(contains('HOSTILE_STACK_SECRET')));
      }
    });

    testWidgets('copying many oversized logs stays within the document budget',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String captured;
      ISpectRedaction.enabled = false;
      final payload = List<String>.filled(72 * 1024, 'x').join();
      final logs = List<ISpectLogData>.generate(
        160,
        (index) => ISpectLogData('$index:$payload'),
      );

      controller.copyAllLogsToClipboard(
        ctx,
        logs,
        (_, {required value, title, showValue}) => captured = value,
        'All logs',
      );

      expect(
        LogExportOutput.utf8Length(captured),
        lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
      );
      expect('\n'.allMatches(captured).length + 1, lessThan(logs.length));
    });

    testWidgets('clipboard paths honor the global redaction opt-out',
        (tester) async {
      final ctx = await pumpContext(tester);
      late String capturedSingle;
      late String capturedAll;
      ISpectRedaction.enabled = false;
      final log = ISpectLogData(
        'failed https://example.test/users?token=COPY_GLOBAL_RAW',
      );

      controller
        ..copyLogEntryText(
          ctx,
          log,
          (_, {required value}) => capturedSingle = value,
        )
        ..copyAllLogsToClipboard(
          ctx,
          [log],
          (_, {required value, title, showValue}) => capturedAll = value,
          'All logs',
        );

      expect(capturedSingle, contains('COPY_GLOBAL_RAW'));
      expect(capturedAll, contains('COPY_GLOBAL_RAW'));
    });
  });
}

final class _InvocationCounters {
  int toJsonCalls = 0;
  int toStringCalls = 0;
}

final class _HostileAdditionalValue {
  _HostileAdditionalValue(this.calls);

  final _InvocationCounters calls;

  Object? toJson() {
    calls.toJsonCalls++;
    return const {'secret': 'CALLER_TO_JSON_SECRET'};
  }

  @override
  String toString() {
    calls.toStringCalls++;
    return 'CALLER_TO_STRING_SECRET';
  }
}

final class _HostileException implements Exception {
  _HostileException(this.calls);

  final _InvocationCounters calls;

  @override
  String toString() {
    calls.toStringCalls++;
    return 'HOSTILE_EXCEPTION_SECRET';
  }
}

final class _HostileError extends Error {
  _HostileError(this.calls);

  final _InvocationCounters calls;

  @override
  String toString() {
    calls.toStringCalls++;
    return 'HOSTILE_ERROR_SECRET';
  }
}

final class _HostileStackTrace implements StackTrace {
  _HostileStackTrace(this.calls);

  final _InvocationCounters calls;

  @override
  String toString() {
    calls.toStringCalls++;
    return 'HOSTILE_STACK_SECRET';
  }
}
