import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/http_composer/presentation/screens/http_composer_screen.dart';

import '../../helpers/pump_ispect.dart';

class _FakeSender implements NetworkRequestSender {
  NetworkReplayRequest? received;

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async {
    received = request;
    return const NetworkReplayResult(statusCode: 200);
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

    testWidgets('hides the send button when no client is registered',
        (tester) async {
      await tester.pumpWidget(
        appShell(const HttpComposerScreen(senders: [])),
      );

      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });
  });
}
