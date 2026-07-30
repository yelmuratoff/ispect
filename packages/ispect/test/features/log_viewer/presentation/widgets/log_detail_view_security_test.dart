import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';

import '../../../../helpers/pump_ispect.dart';

void main() {
  tearDown(ISpectRedaction.reset);

  testWidgets('build does not re-execute captured diagnostic methods',
      (tester) async {
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
    final toJsonCallsAtCapture = calls.toJsonCalls;
    final toStringCallsAtCapture = calls.toStringCalls;

    await tester.pumpWidget(
      appShell(LogDetailView(activeData: log)),
    );

    expect(tester.takeException(), isNull);
    expect(calls.toJsonCalls, toJsonCallsAtCapture);
    expect(calls.toStringCalls, toStringCallsAtCapture);
    final screen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    expect(
      screen.data['additional-data'],
      containsPair(
        'custom',
        containsPair('secret', isNot('CALLER_TO_JSON_SECRET')),
      ),
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

  testWidgets('a replacement global redaction policy refreshes the snapshot',
      (tester) async {
    const policyKey = 'policy_specific_field';
    const rawValue = 'visible project value';
    final log = ISpectLogData(
      'policy-sensitive detail',
      additionalData: const {policyKey: rawValue},
    );
    ISpectRedaction.configure(
      service: RedactionService(
        additionalSensitiveKeys: const {'first_policy_key'},
      ),
    );

    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    final firstScreen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    final firstAdditional =
        firstScreen.data['additional-data']! as Map<String, dynamic>;

    ISpectRedaction.configure(
      service: RedactionService(
        additionalSensitiveKeys: const {policyKey},
      ),
    );
    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    final replacementScreen = tester.widget<JsonScreen>(
      find.byType(JsonScreen),
    );
    final replacementAdditional =
        replacementScreen.data['additional-data']! as Map<String, dynamic>;

    expect(firstAdditional[policyKey], rawValue);
    expect(replacementAdditional[policyKey], isNot(rawValue));
    expect(replacementScreen.key, isNot(firstScreen.key));
  });

  testWidgets('an in-place policy mutation invalidates the cached snapshot',
      (tester) async {
    const policyKey = 'mutable_policy_field';
    const rawValue = 'visible mutable value';
    final service = RedactionService(
      additionalSensitiveKeys: const {policyKey},
    )..ignoreKey(policyKey);
    ISpectRedaction.configure(service: service);
    final log = ISpectLogData(
      'mutable policy detail',
      additionalData: const {policyKey: rawValue},
    );

    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    final firstScreen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    final firstAdditional =
        firstScreen.data['additional-data']! as Map<String, dynamic>;

    service.unignoreKey(policyKey);
    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    final replacementScreen = tester.widget<JsonScreen>(
      find.byType(JsonScreen),
    );
    final replacementAdditional =
        replacementScreen.data['additional-data']! as Map<String, dynamic>;

    expect(firstAdditional[policyKey], rawValue);
    expect(replacementAdditional[policyKey], isNot(rawValue));
    expect(replacementScreen.key, isNot(firstScreen.key));
  });

  testWidgets('correlation banner follows the global redaction policy',
      (tester) async {
    const rawSecret = 'CORRELATED_BANNER_SECRET';
    final active = ISpectLogData(
      'request',
      key: ISpectLogType.httpRequest.key,
    );
    final correlated = ISpectLogData(
      'GET https://api.example.test/items?token=$rawSecret',
      key: ISpectLogType.httpResponse.key,
    );

    await tester.pumpWidget(
      appShell(
        LogDetailView(
          activeData: active,
          correlatedLog: correlated,
          onNavigateToCorrelated: () {},
        ),
      ),
    );
    expect(find.textContaining(rawSecret), findsNothing);

    ISpectRedaction.enabled = false;
    await tester.pumpWidget(
      appShell(
        LogDetailView(
          activeData: active,
          correlatedLog: correlated,
          onNavigateToCorrelated: () {},
        ),
      ),
    );
    expect(find.textContaining(rawSecret), findsOneWidget);
  });

  testWidgets('trace chips display and copy redacted identifiers',
      (tester) async {
    const correlationSecret = 'TRACE_CORRELATION_SECRET';
    const transactionSecret = 'TRACE_TRANSACTION_SECRET';
    String? copiedText;
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final log = ISpectLogData(
      'trace identifiers',
      additionalData: const {
        TraceKeys.correlationId: 'Bearer $correlationSecret',
        TraceKeys.transactionId:
            'https://api.example.test/session?token=$transactionSecret',
      },
    );

    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));

    expect(find.textContaining(correlationSecret), findsNothing);
    expect(find.textContaining(transactionSecret), findsNothing);

    await tester.tap(find.textContaining('Corr:'));
    await tester.pump();
    expect(copiedText, isNot(contains(correlationSecret)));

    await tester.tap(find.textContaining('Txn:'));
    await tester.pump();
    expect(copiedText, isNot(contains(transactionSecret)));

    ISpectRedaction.enabled = false;
    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    expect(find.textContaining(correlationSecret), findsWidgets);
    expect(find.textContaining(transactionSecret), findsWidgets);
  });

  testWidgets('a throwing view redactor fails closed unless globally disabled',
      (tester) async {
    const rawSecret = 'THROWING_VIEW_REDACTOR_SECRET';
    ISpectRedaction.configure(service: _ThrowingViewRedactionService());
    final log = ISpectLogData(
      rawSecret,
      additionalData: const {
        TraceKeys.correlationId: 'Bearer $rawSecret',
      },
    );

    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining(rawSecret), findsNothing);
    final screen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    expect(
      screen.data['message'],
      JsonValueNormalizer.unprintableValue,
    );

    ISpectRedaction.enabled = false;
    await tester.pumpWidget(appShell(LogDetailView(activeData: log)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining(rawSecret), findsWidgets);
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

final class _ThrowingViewRedactionService extends RedactionService {
  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      throw StateError('view envelope redaction failed');

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      throw StateError('view text redaction failed');
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
