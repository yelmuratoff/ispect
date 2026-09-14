import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_desktop_row.dart';
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

  for (final variant in [
    (width: 1200.0, textScale: 1.0),
    (width: 1200.0, textScale: 2.0),
    (width: 600.0, textScale: 1.0),
  ]) {
    testWidgets(
      'desktop hover keeps row height at ${variant.width}px and ${variant.textScale}x text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1200, 800);
        addTearDown(tester.view.reset);
        String? openedDetail;
        final transaction = NetworkTransaction(
          requestId: 'request-1',
          request: ISpectLogData(
            'GET /users',
            key: ISpectLogType.httpRequest.key,
            additionalData: const {
              TraceKeys.operation: 'GET',
              TraceKeys.target: 'https://api.example.com/users',
            },
          ),
          response: ISpectLogData(
            'OK',
            key: ISpectLogType.httpResponse.key,
            additionalData: const {
              TraceKeys.meta: {
                NetworkJsonKeys.statusCode: 200,
                TraceKeys.durationMs: 301,
              },
            },
          ),
        );
        await tester.pumpWidget(
          appShell(
            ISpectThemeScope(
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(1200, 800),
                  textScaler: TextScaler.linear(variant.textScale),
                ),
                child: SizedBox(
                  width: variant.width,
                  child: Column(
                    children: [
                      NetworkTransactionCard(
                        transaction: transaction,
                        onOpenRequestDetail: () => openedDetail = 'request',
                        onOpenResponseDetail: () => openedDetail = 'response',
                      ),
                      const SizedBox(key: Key('next-row'), height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final row = find.byType(NetworkTransactionDesktopRow);
        final initialHeight = tester.getSize(row).height;
        if (variant.textScale == 1) {
          expect(initialHeight, lessThan(kMinInteractiveDimension));
        }
        final nextRowPosition = tester.getTopLeft(
          find.byKey(const Key('next-row')),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: const Offset(1100, 790));
        await mouse.moveTo(tester.getCenter(find.text('/users')));
        await tester.pumpAndSettle();

        expect(tester.getSize(row).height, initialHeight);
        expect(
          tester.getTopLeft(find.byKey(const Key('next-row'))),
          nextRowPosition,
        );
        expect(find.byType(DetailChip), findsNWidgets(2));
        for (final entry in {
          'Request': 'request',
          'Response': 'response',
        }.entries) {
          final action = find.byWidgetPredicate(
            (widget) => widget is DetailChip && widget.label == entry.key,
          );
          await mouse.moveTo(tester.getCenter(action));
          await mouse.down(tester.getCenter(action));
          await mouse.up();
          await tester.pumpAndSettle();
          expect(openedDetail, entry.value);
        }
        await mouse.moveTo(const Offset(1100, 790));
        await tester.pumpAndSettle();
        expect(find.byType(DetailChip), findsNothing);
        expect(tester.getSize(row).height, initialHeight);
        expect(
          tester.getTopLeft(find.byKey(const Key('next-row'))),
          nextRowPosition,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'mobile disclosure is accessible and keyboard operable at large text scale',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        var detailOpened = false;
        final transaction = NetworkTransaction(
          requestId: 'request-1',
          request: ISpectLogData(
            'GET /users',
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
            ISpectThemeScope(
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 800),
                  textScaler: TextScaler.linear(2),
                ),
                child: NetworkTransactionCard(
                  transaction: transaction,
                  onOpenRequestDetail: () => detailOpened = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        final disclosure = find.byTooltip('Expand logs');
        expect(tester.getSize(disclosure), const Size(48, 48));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Collapse logs'), findsOneWidget);
        expect(detailOpened, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Expand logs'), findsOneWidget);
        expect(detailOpened, isFalse);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final variant in <({String name, Size size})>[
    (name: 'mobile', size: const Size(400, 800)),
    (name: 'desktop', size: const Size(1200, 800)),
  ]) {
    for (final outcome in ['response', 'error', 'pending']) {
      testWidgets(
        '${variant.name} grouped $outcome opens Actions on long press',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = variant.size;
          addTearDown(tester.view.reset);
          var tapped = false;
          String? openedDetail;
          final transaction = NetworkTransaction(
            requestId: 'request-1',
            request: ISpectLogData(
              'GET /users',
              key: ISpectLogType.httpRequest.key,
              additionalData: const {
                TraceKeys.category: TraceCategoryIds.network,
                TraceKeys.operation: 'GET',
                TraceKeys.target: 'https://api.example.com/users',
              },
            ),
            response: outcome == 'response'
                ? ISpectLogData('OK', key: ISpectLogType.httpResponse.key)
                : null,
            error: outcome == 'error'
                ? ISpectLogData('Failed', key: ISpectLogType.httpError.key)
                : null,
          );
          await tester.pumpWidget(
            appShell(
              NetworkTransactionCard(
                transaction: transaction,
                onTap: () => tapped = true,
                onOpenRequestDetail: () => openedDetail = 'request',
                onOpenResponseDetail: outcome == 'pending'
                    ? null
                    : () => openedDetail = outcome,
              ),
            ),
          );
          await tester.longPress(find.text('/users'));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
          expect(find.byIcon(Icons.share_rounded), findsOneWidget);
          expect(find.text('HTTP Request'), findsOneWidget);
          expect(tapped, isFalse);
          expect(openedDetail, isNull);
          expect(find.byTooltip('Collapse logs'), findsNothing);

          if (outcome != 'pending') {
            await tester.tap(find.byIcon(Icons.share_rounded));
            await tester.pumpAndSettle();
            expect(find.text('Request'), findsOneWidget);
            expect(find.text('Response'), findsOneWidget);
            Navigator.of(
              tester.element(find.byType(NetworkTransactionCard)),
            ).pop();
            await tester.pumpAndSettle();
            await tester.longPress(find.text('/users'));
            await tester.pumpAndSettle();
          }

          await tester.tap(find.byIcon(Icons.open_in_full_rounded));
          await tester.pumpAndSettle();
          expect(openedDetail, outcome == 'pending' ? 'request' : outcome);
          expect(find.byIcon(Icons.content_copy_rounded), findsNothing);
          expect(tapped, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('${variant.name} grouped card shows a redacted query URL', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = variant.size;
      addTearDown(tester.view.reset);
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
          NetworkTransactionCard(transaction: transaction, compactUrl: false),
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

    testWidgets(
      '${variant.name} grouped card honours the relative time setting',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = variant.size;
        addTearDown(tester.view.reset);
        await tester.binding.setSurfaceSize(variant.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final transaction = NetworkTransaction(
          requestId: 'request-1',
          request: ISpectLogData(
            '→ GET https://api.example.com/users',
            key: ISpectLogType.httpRequest.key,
            time: DateTime.now().subtract(const Duration(minutes: 12)),
            additionalData: const {
              TraceKeys.category: TraceCategoryIds.network,
              TraceKeys.operation: 'GET',
              TraceKeys.target: 'https://api.example.com/users',
            },
          ),
        );

        await tester.pumpWidget(
          appShell(NetworkTransactionCard(transaction: transaction)),
        );
        await tester.pumpAndSettle();
        expect(find.text('12 min ago'), findsNothing);

        await tester.pumpWidget(
          appShell(
            NetworkTransactionCard(
              transaction: transaction,
              useRelativeTime: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('12 min ago'), findsOneWidget);
      },
    );

    testWidgets('${variant.name} grouped card does not re-redact its payload', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = variant.size;
      addTearDown(tester.view.reset);
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
                NetworkJsonKeys.queryParameters: {'token': defaultPlaceholder},
                NetworkJsonKeys.headers: {'Authorization': defaultPlaceholder},
              },
            },
          },
        ),
      );

      await tester.pumpWidget(
        appShell(
          NetworkTransactionCard(transaction: transaction, compactUrl: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(redactor.structuredExportCalls, 0);
    });

    testWidgets('${variant.name} grouped card uses a Material ripple on tap', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = variant.size;
      addTearDown(tester.view.reset);
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

      expect(
        find.byType(NetworkTransactionDesktopRow),
        variant.name == 'desktop' ? findsOneWidget : findsNothing,
      );
      final card = find.byType(NetworkTransactionCard);
      final ripple = find.ancestor(
        of: find.text('/users'),
        matching: find.byType(InkWell),
      );
      expect(ripple, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(Material)),
        findsWidgets,
      );

      await tester.tap(ripple);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });
  }
}
