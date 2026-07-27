import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';

import '../../../../helpers/pump_ispect.dart';

void main() {
  tearDown(() => ISpectRedaction.enabled = true);

  testWidgets('build never executes caller diagnostic methods', (tester) async {
    final calls = _InvocationCounters();
    final log = ISpectLogData(
      'safe message',
      exception: _HostileException(calls),
      error: _HostileError(calls),
      stackTrace: _HostileStackTrace(calls),
      additionalData: {
        'custom': _HostileAdditionalValue(calls),
        'oversized': List<String>.filled(2 * 1024 * 1024, 'x').join(),
      },
    );

    await tester.pumpWidget(
      appShell(LogDetailView(activeData: log)),
    );

    expect(tester.takeException(), isNull);
    expect(calls.toJsonCalls, 0);
    expect(calls.toStringCalls, 0);
    final screen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    expect(
      screen.data['additional-data'],
      containsPair('custom', JsonValueNormalizer.unprintableValue),
    );
  });

  testWidgets('build honors the explicit global redaction opt-out',
      (tester) async {
    ISpectRedaction.enabled = false;
    final log = ISpectLogData('RAW_DETAIL_VALUE');

    await tester.pumpWidget(
      appShell(LogDetailView(activeData: log)),
    );

    final screen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    expect(screen.data['message'], 'RAW_DETAIL_VALUE');
  });

  testWidgets('malformed trace identifiers do not break the detail view',
      (tester) async {
    final log = ISpectLogData(
      'malformed imported trace metadata',
      additionalData: const {
        TraceKeys.correlationId: <String>['not', 'an', 'id'],
        TraceKeys.transactionId: <String, Object?>{'not': 'an id'},
      },
    );

    await tester.pumpWidget(
      appShell(LogDetailView(activeData: log)),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(JsonScreen), findsOneWidget);
  });

  testWidgets('reuses the bounded snapshot when the same log rebuilds',
      (tester) async {
    final log = ISpectLogData(
      'stable detail',
      additionalData: const {
        'payload': <String, Object?>{'value': 42},
      },
    );

    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    final firstSnapshot =
        tester.widget<JsonScreen>(find.byType(JsonScreen)).data;

    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    final rebuiltSnapshot =
        tester.widget<JsonScreen>(find.byType(JsonScreen)).data;

    expect(identical(rebuiltSnapshot, firstSnapshot), isTrue);
  });

  testWidgets(
    'callback updates do not rebuild the snapshot and use the latest callback',
    (tester) async {
      final log = ISpectLogData('stable callback detail');
      var firstCallbackCalls = 0;
      var latestCallbackCalls = 0;

      await tester.pumpWidget(
        appShell(
          LogDetailView(
            activeData: log,
            onClose: () => firstCallbackCalls++,
          ),
        ),
      );
      final firstSnapshot =
          tester.widget<JsonScreen>(find.byType(JsonScreen)).data;

      await tester.pumpWidget(
        appShell(
          LogDetailView(
            activeData: log,
            onClose: () => latestCallbackCalls++,
          ),
        ),
      );
      final rebuiltSnapshot =
          tester.widget<JsonScreen>(find.byType(JsonScreen)).data;

      expect(identical(rebuiltSnapshot, firstSnapshot), isTrue);
      final closeButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.arrow_back_rounded),
          matching: find.byType(IconButton),
        ),
      );
      closeButton.onPressed?.call();

      expect(firstCallbackCalls, 0);
      expect(latestCallbackCalls, 1);
    },
  );
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
