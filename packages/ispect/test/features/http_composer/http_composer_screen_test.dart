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

final class _BaseUrlSender
    implements NetworkRequestSender, NetworkBaseUrlProvider {
  _BaseUrlSender(this.label, this.baseUrl);

  @override
  final String label;

  @override
  final Uri baseUrl;

  @override
  String get id => label;

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async =>
      const NetworkReplayResult(statusCode: 200);
}

final class _HostileReplayError implements Exception {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw StateError('REPLAY_SCREEN_JSON_SECRET');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('REPLAY_SCREEN_TEXT_SECRET');
  }
}

void main() {
  group('HttpComposerScreen', () {
    testWidgets('sends the composed request and shows the response status', (
      tester,
    ) async {
      final sender = _FakeSender();
      await tester.pumpWidget(appShell(HttpComposerScreen(senders: [sender])));

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

    testWidgets('the URL field follows the base URL of the chosen client', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(
          HttpComposerScreen(
            senders: [
              _BaseUrlSender('Api', Uri.parse('https://api.test')),
              _BaseUrlSender('Cdn', Uri.parse('https://cdn.test')),
            ],
          ),
        ),
      );
      TextField urlField() =>
          tester.widget<TextField>(find.byType(TextField).first);

      expect(urlField().controller!.text, 'https://api.test');

      await tester.tap(find.text('Api'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cdn').last);
      await tester.pumpAndSettle();

      expect(urlField().controller!.text, 'https://cdn.test');
    });

    Future<void> openCustomMethod(WidgetTester tester) async {
      await tester.tap(find.text('GET'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('composer-custom-method')));
      await tester.pumpAndSettle();
    }

    testWidgets('sends a custom method the user typed', (tester) async {
      final sender = _FakeSender();
      await tester.pumpWidget(appShell(HttpComposerScreen(senders: [sender])));

      await openCustomMethod(tester);
      await tester.enterText(find.byType(TextField).last, ' search ');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/items',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('SEARCH'), findsOneWidget);
      expect(sender.received?.method, 'SEARCH');
    });

    testWidgets('an invalid custom method keeps the dialog open', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(HttpComposerScreen(senders: [_FakeSender()])),
      );

      await openCustomMethod(tester);
      await tester.enterText(find.byType(TextField).last, 'not a method');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter one word without spaces, like SEARCH'),
        findsOneWidget,
      );
      expect(find.text('Custom method'), findsOneWidget);
    });

    testWidgets('the custom method field is named without a floating label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(HttpComposerScreen(senders: [_FakeSender()])),
      );

      await openCustomMethod(tester);
      final field = find.byType(TextField).last;

      expect(tester.widget<TextField>(field).decoration?.labelText, isNull);
      expect(tester.getSemantics(field).label, contains('Method'));
      semantics.dispose();
    });

    testWidgets('says which redacted values were not copied from the log', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShell(
          HttpComposerScreen(
            senders: [_FakeSender()],
            replay: ParsedReplayRequest(
              request: NetworkReplayRequest(
                method: 'PUT',
                uri: Uri.parse('https://api.test/profile'),
              ),
              redactedHeaderKeys: const {'X-Token', 'Cookie'},
              bodyRedacted: true,
            ),
          ),
        ),
      );

      expect(
        find.text(
          "The body was redacted in the log and wasn't copied. "
          'Enter it again before sending.',
        ),
        findsOneWidget,
      );
      expect(
        find.text("Redacted headers weren't copied: Cookie, X-Token"),
        findsOneWidget,
      );
    });

    testWidgets('shows no notice when everything was copied', (tester) async {
      await tester.pumpWidget(
        appShell(
          HttpComposerScreen(
            senders: [_FakeSender()],
            replay: ParsedReplayRequest(
              request: NetworkReplayRequest(
                method: 'GET',
                uri: Uri.parse('https://api.test/ping'),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('composer-withheld-notice')),
        findsNothing,
      );
    });

    testWidgets('opens the JSON viewer for a JSON response body', (
      tester,
    ) async {
      final sender = _FakeSender(
        result: const NetworkReplayResult(
          statusCode: 200,
          body: {'name': 'Ada'},
        ),
      );
      await tester.pumpWidget(appShell(HttpComposerScreen(senders: [sender])));

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

    testWidgets('hides the send button when no client is registered', (
      tester,
    ) async {
      await tester.pumpWidget(appShell(const HttpComposerScreen(senders: [])));

      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });

    testWidgets('splits request and response into two panes on desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final sender = _FakeSender(
        result: const NetworkReplayResult(
          statusCode: 200,
          body: {'name': 'Ada'},
        ),
      );
      await tester.pumpWidget(appShell(HttpComposerScreen(senders: [sender])));

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
      await tester.pumpWidget(appShell(HttpComposerScreen(senders: [sender])));

      expect(find.byType(ResizableSplitView), findsNothing);

      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/ping',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('renders a hostile sender error without invoking formatters', (
      tester,
    ) async {
      final error = _HostileReplayError();
      final sender = _FakeSender(result: NetworkReplayResult(error: error));
      await tester.pumpWidget(appShell(HttpComposerScreen(senders: [sender])));

      await tester.enterText(
        find.byType(TextField).first,
        'https://api.test/ping',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(error.toJsonCalls, 0);
      expect(error.toStringCalls, 0);
      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('REPLAY_SCREEN_'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
