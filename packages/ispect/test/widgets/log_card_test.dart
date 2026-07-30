import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_card.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('LogCard', () {
    ISpectLogData makeLogData({
      String message = 'Test message',
      String key = 'info',
      DateTime? time,
      Map<String, dynamic>? additionalData,
    }) =>
        ISpectLogData(
          message,
          key: key,
          time: time ?? DateTime(2024, 1, 1, 12),
          additionalData: additionalData,
        );

    Widget buildLogCard({
      ISpectLogData? data,
      bool isExpanded = false,
      VoidCallback? onTap,
      SearchMatchState searchMatchState = SearchMatchState.none,
    }) =>
        appShell(
          SingleChildScrollView(
            child: LogCard(
              icon: Icons.info_outline,
              color: Colors.blue,
              data: data ?? makeLogData(),
              index: 0,
              isExpanded: isExpanded,
              onTap: onTap ?? () {},
              searchMatchState: searchMatchState,
            ),
          ),
        );

    testWidgets(
      'Given a collapsed LogCard, '
      'When it is rendered, '
      'Then it finds LogCard widget and shows collapsed message',
      (tester) async {
        await tester.pumpWidget(buildLogCard());
        await tester.pumpAndSettle();

        expect(find.byType(LogCard), findsOneWidget);
        expect(find.text('Test message'), findsOneWidget);
      },
    );

    testWidgets('subtitle does not re-inspect a hostile diagnostic',
        (tester) async {
      final hostile = _HostileRuntimeTypeError();
      final data = ISpectLogData('safe message', error: hostile);
      final callsAtCapture = hostile.calls;

      await tester.pumpWidget(buildLogCard(data: data));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(hostile.calls, callsAtCapture);
      expect(
        find.textContaining(JsonValueNormalizer.unprintableValue),
        findsWidgets,
      );
    });

    testWidgets(
      'Given a LogCard with key "info", '
      'When it is rendered, '
      'Then it shows the log type title',
      (tester) async {
        await tester.pumpWidget(buildLogCard());
        await tester.pumpAndSettle();

        // ISpectLogType.fromKey('info')?.displayTitle == 'info'
        expect(find.text('info'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a LogCard with time 12:00:00, '
      'When it is rendered, '
      'Then it shows the formatted time',
      (tester) async {
        await tester.pumpWidget(buildLogCard());
        await tester.pumpAndSettle();

        // formattedTime for DateTime(2024, 1, 1, 12, 0, 0) = "12:00:00 | 0ms"
        expect(find.textContaining('12:00:00'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a LogCard with an onTap callback, '
      'When the header is tapped, '
      'Then the onTap callback is invoked',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          buildLogCard(onTap: () => tapped = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'Given an expanded LogCard, '
      'When it is rendered, '
      'Then the expanded content is visible',
      (tester) async {
        await tester.pumpWidget(
          buildLogCard(
            data: makeLogData(message: 'Expanded log content'),
            isExpanded: true,
          ),
        );
        await tester.pumpAndSettle();

        // Expanded content shows a Divider and the full message via
        // SelectableText.
        expect(find.byType(Divider), findsOneWidget);
        expect(find.text('Expanded log content'), findsWidgets);
      },
    );

    testWidgets(
      'Given a collapsed LogCard, '
      'When it is rendered, '
      'Then action buttons are visible',
      (tester) async {
        await tester.pumpWidget(buildLogCard());
        await tester.pumpAndSettle();

        // At minimum: share + expand buttons.
        expect(find.byType(SquareIconButton), findsWidgets);
      },
    );

    testWidgets(
      'Given an HTTP LogCard with statusCode 200, '
      'When it is rendered, '
      'Then it shows the status code badge',
      (tester) async {
        final data = ISpectLogData(
          'GET /api/users',
          key: 'http-request',
          time: DateTime(2024, 1, 1, 12),
          additionalData: const {
            'meta': {'statusCode': 200},
          },
        );

        await tester.pumpWidget(buildLogCard(data: data));
        await tester.pumpAndSettle();

        expect(find.text('200'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a LogCard with searchMatchState == focused, '
      'When it is rendered, '
      'Then the card has a shadow decoration',
      (tester) async {
        await tester.pumpWidget(
          buildLogCard(searchMatchState: SearchMatchState.focused),
        );
        await tester.pumpAndSettle();

        // The outermost DecoratedBox should carry the focused-match glow.
        final decoratedBox = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(RepaintBoundary),
            matching: find.byType(DecoratedBox).first,
          ),
        );
        final decoration = decoratedBox.decoration as ShapeDecoration;
        expect(decoration.shadows, isNotNull);
        expect(decoration.shadows, isNotEmpty);
      },
    );

    testWidgets(
      'Given a LogCard, '
      'When it is rendered, '
      'Then the header exposes a button Semantics node with the log label',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          buildLogCard(
            data: makeLogData(message: 'Semantic label message'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(RegExp('info.*Semantic label message')),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'Given an HTTP LogCard with statusCode 404, '
      'When it is rendered, '
      'Then the status badge exposes a semantic label with the code',
      (tester) async {
        final data = ISpectLogData(
          'GET /api/missing',
          key: 'http-request',
          time: DateTime(2024, 1, 1, 12),
          additionalData: const {
            'meta': {'statusCode': 404},
          },
        );

        final handle = tester.ensureSemantics();
        await tester.pumpWidget(buildLogCard(data: data));
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel('HTTP status 404'),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'Given a LogCard, '
      'When the action buttons are laid out, '
      'Then each SquareIconButton keeps the minimum interactive tap height',
      (tester) async {
        await tester.pumpWidget(buildLogCard());
        await tester.pumpAndSettle();

        final buttons = find.byType(SquareIconButton);
        expect(buttons, findsWidgets);
        for (final element in buttons.evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
        }
      },
    );

    testWidgets(
      'copy message retains binary provenance until context-menu redaction',
      (tester) async {
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
        ISpectRedaction.enabled = false;
        final data = ISpectLogData(
          Uint8List.fromList(List<int>.filled(64, 211)),
          key: 'info',
        );
        ISpectRedaction.enabled = true;

        await tester.pumpWidget(buildLogCard(data: data));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.content_copy_rounded));
        await tester.pumpAndSettle();

        expect(clipboardText, isNotNull);
        expect(clipboardText, isNot(contains('211, 211, 211')));
        expect(clipboardText, '[binary 64 bytes]');
      },
    );
  });
}

final class _HostileRuntimeTypeError extends Error {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('HOSTILE_LOG_CARD_RUNTIME_TYPE');
  }

  @override
  String toString() {
    calls++;
    throw StateError('HOSTILE_LOG_CARD_FORMATTER');
  }
}
