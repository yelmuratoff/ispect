import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_card.dart';
import 'package:ispectify/ispectify.dart';

import '../../../../../helpers/pump_ispect.dart';

final class _CountingRedactionService extends RedactionService {
  int structuredExportCalls = 0;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (data is Map<Object?, Object?>) structuredExportCalls++;
    return super.redactForExport(
      data,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
  }
}

void main() {
  tearDown(ISpectRedaction.reset);

  for (final variant in <({String name, Size size})>[
    (name: 'mobile', size: const Size(400, 800)),
    (name: 'desktop', size: const Size(1200, 800)),
  ]) {
    testWidgets('${variant.name} grouped card shows a redacted query URL',
        (tester) async {
      await tester.binding.setSurfaceSize(variant.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final request = ISpectLogData(
        '→ GET https://api.example.com/users',
        key: ISpectLogType.httpRequest.key,
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          TraceKeys.operation: 'GET',
          TraceKeys.target: 'https://api.example.com/users',
          TraceKeys.meta: {
            NetworkJsonKeys.requestData: {
              NetworkJsonKeys.method: 'GET',
              NetworkJsonKeys.queryParameters: {
                'page': 2,
                'token': defaultPlaceholder,
              },
            },
          },
        },
      );
      final transaction = NetworkTransaction(
        requestId: 'request-1',
        request: request,
      );

      await tester.pumpWidget(
        appShell(
          NetworkTransactionCard(
            transaction: transaction,
            compactUrl: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'https://api.example.com/users?page=2&token=$defaultPlaceholder',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('secret'), findsNothing);
    });

    testWidgets('${variant.name} grouped card does not re-redact its payload',
        (tester) async {
      await tester.binding.setSurfaceSize(variant.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final redactor = _CountingRedactionService();
      ISpectRedaction.configure(service: redactor);
      final transaction = NetworkTransaction(
        requestId: 'request-1',
        request: ISpectLogData(
          '→ GET https://api.example.com/users',
          key: ISpectLogType.httpRequest.key,
          additionalData: const {
            TraceKeys.category: TraceCategoryIds.network,
            TraceKeys.operation: 'GET',
            TraceKeys.target: 'https://api.example.com/users',
            TraceKeys.meta: {
              NetworkJsonKeys.requestData: {
                NetworkJsonKeys.queryParameters: {
                  'token': defaultPlaceholder,
                },
                NetworkJsonKeys.headers: {
                  'Authorization': defaultPlaceholder,
                },
              },
            },
          },
        ),
      );

      await tester.pumpWidget(
        appShell(
          NetworkTransactionCard(
            transaction: transaction,
            compactUrl: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(redactor.structuredExportCalls, 0);
    });

    testWidgets('${variant.name} grouped card uses a Material ripple on tap',
        (tester) async {
      await tester.binding.setSurfaceSize(variant.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var tapCount = 0;
      final transaction = NetworkTransaction(
        requestId: 'request-1',
        request: ISpectLogData(
          '→ GET https://api.example.com/users',
          key: ISpectLogType.httpRequest.key,
          additionalData: const {
            TraceKeys.category: TraceCategoryIds.network,
            TraceKeys.operation: 'GET',
            TraceKeys.target: 'https://api.example.com/users',
          },
        ),
      );

      await tester.pumpWidget(
        appShell(
          NetworkTransactionCard(
            transaction: transaction,
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byType(NetworkTransactionCard);
      final ripple = find.descendant(
        of: card,
        matching: find.byType(InkWell),
      );
      expect(ripple, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(Material)),
        findsOneWidget,
      );

      await tester.tap(ripple);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });
  }
}
