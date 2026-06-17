import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/http_composer/presentation/screens/http_composer_screen.dart';

import '../../helpers/pump_ispect.dart';

class _FakeSender implements NetworkRequestSender {
  _FakeSender({this.result = const NetworkReplayResult(statusCode: 200)});

  final NetworkReplayResult result;
  NetworkReplayRequest? received;

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async {
    received = request;
    return result;
  }
}

void main() {
  group('HttpComposerScreen', () {
    testWidgets('sends the composed request and shows the response status',
        (tester) async {
      final sender = _FakeSender();
      await tester.pumpWidget(
        appShell(HttpComposerScreen(senders: [sender])),
      );

      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/ping',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(sender.received, isNotNull);
      expect(sender.received!.uri.toString(), 'https://api.test/ping');
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('opens the JSON viewer for a JSON response body',
        (tester) async {
      final sender = _FakeSender(
        result: const NetworkReplayResult(
          statusCode: 200,
          body: {'name': 'Ada'},
        ),
      );
      await tester.pumpWidget(
        appShell(HttpComposerScreen(senders: [sender])),
      );

      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/users',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final viewerAction = find.byIcon(Icons.data_object_rounded);
      expect(viewerAction, findsOneWidget);

      await tester.ensureVisible(viewerAction);
      await tester.pumpAndSettle();
      await tester.tap(viewerAction);
      await tester.pumpAndSettle();

      expect(find.byType(JsonScreen), findsOneWidget);
    });

    testWidgets('hides the send button when no client is registered',
        (tester) async {
      await tester.pumpWidget(
        appShell(const HttpComposerScreen(senders: [])),
      );

      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('splits request and response into two panes on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final sender = _FakeSender(
        result: const NetworkReplayResult(
          statusCode: 200,
          body: {'name': 'Ada'},
        ),
      );
      await tester.pumpWidget(
        appShell(HttpComposerScreen(senders: [sender])),
      );

      expect(find.byType(ResizableSplitView), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/ping',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inbox_rounded), findsNothing);
      expect(find.text('200'), findsOneWidget);

      final hasEnlargedPreview = tester
          .widgetList<Text>(find.byType(Text))
          .any((text) => (text.maxLines ?? 0) > 12);
      expect(hasEnlargedPreview, isTrue);
    });

    testWidgets('keeps a single pane on a narrow window', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final sender = _FakeSender();
      await tester.pumpWidget(
        appShell(HttpComposerScreen(senders: [sender])),
      );

      expect(find.byType(ResizableSplitView), findsNothing);

      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/ping',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('200'), findsOneWidget);
    });
  });
}
