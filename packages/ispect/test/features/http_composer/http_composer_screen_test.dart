import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
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
  });
}
