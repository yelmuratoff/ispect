import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/http_composer/controllers/http_composer_controller.dart';

class _RecordingSender implements NetworkRequestSender {
  NetworkReplayRequest? lastRequest;

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async {
    lastRequest = request;
    return const NetworkReplayResult(statusCode: 200);
  }
}

HttpComposerController _controller({
  List<NetworkRequestSender>? senders,
  NetworkReplayRequest? seed,
}) =>
    HttpComposerController(
      senders: senders ?? [_RecordingSender()],
      seed: seed,
    );

void main() {
  group('HttpComposerController.buildReplayRequest', () {
    test('assembles method, url, headers and JSON body', () {
      final controller = _controller()
        ..setMethod('POST')
        ..setUrl('https://api.test/users')
        ..addHeader()
        ..setBodyKind(ComposerBodyKind.json)
        ..setBodyText('{"name":"Ada"}');
      controller.headers.single
        ..key = 'Accept'
        ..value = 'application/json';

      final request = controller.buildReplayRequest();

      expect(request, isNotNull);
      expect(request!.method, 'POST');
      expect(request.uri.toString(), 'https://api.test/users');
      expect(request.headers['Accept'], 'application/json');
      expect(request.body, isA<JsonReplayBody>());
      expect((request.body! as JsonReplayBody).value, {'name': 'Ada'});
      expect(controller.validationError, isNull);
    });

    test('merges query parameter rows into the uri', () {
      final controller = _controller()
        ..setUrl('https://api.test/search')
        ..addQueryParam();
      controller.queryParams.single
        ..key = 'q'
        ..value = 'dart';

      final request = controller.buildReplayRequest();

      expect(request!.uri.queryParameters['q'], 'dart');
    });

    test('rejects an empty url', () {
      final controller = _controller()..setUrl('   ');

      expect(controller.buildReplayRequest(), isNull);
      expect(controller.validationError, ComposerValidation.urlRequired);
    });

    test('rejects a relative url without a scheme', () {
      final controller = _controller()..setUrl('api.test/users');

      expect(controller.buildReplayRequest(), isNull);
      expect(controller.validationError, ComposerValidation.urlInvalid);
    });

    test('reports invalid JSON instead of building a request', () {
      final controller = _controller()
        ..setUrl('https://api.test')
        ..setBodyKind(ComposerBodyKind.json)
        ..setBodyText('{not json}');

      expect(controller.buildReplayRequest(), isNull);
      expect(controller.validationError, ComposerValidation.jsonInvalid);
    });

    test('builds a form-urlencoded body from form rows', () {
      final controller = _controller()
        ..setUrl('https://api.test/form')
        ..setBodyKind(ComposerBodyKind.formUrlEncoded)
        ..addFormField();
      controller.formFields.single
        ..key = 'a'
        ..value = '1';

      final body = controller.buildReplayRequest()!.body;
      expect(body, isA<FormUrlEncodedReplayBody>());
      expect((body! as FormUrlEncodedReplayBody).fields, {'a': '1'});
    });
  });

  group('HttpComposerController.send', () {
    test('sends the built request through the selected client', () async {
      final sender = _RecordingSender();
      final controller = _controller(senders: [sender])
        ..setMethod('GET')
        ..setUrl('https://api.test/ping');

      await controller.send();

      expect(sender.lastRequest, isNotNull);
      expect(sender.lastRequest!.uri.toString(), 'https://api.test/ping');
      expect(controller.result?.statusCode, 200);
      expect(controller.isSending, isFalse);
    });

    test('does nothing and flags an error when no client is registered',
        () async {
      final controller = _controller(senders: [])..setUrl('https://api.test');

      await controller.send();

      expect(controller.result, isNull);
      expect(controller.validationError, ComposerValidation.noClient);
    });
  });

  group('HttpComposerController seed', () {
    test('prefills method, url, headers and a JSON body from a request', () {
      final controller = _controller(
        seed: NetworkReplayRequest(
          method: 'PUT',
          uri: Uri.parse('https://api.test/users'),
          headers: const {'Authorization': 'Bearer x'},
          body: const JsonReplayBody({'a': 1}),
        ),
      );

      expect(controller.method, 'PUT');
      expect(controller.url, 'https://api.test/users');
      expect(controller.headers.single.key, 'Authorization');
      expect(controller.bodyKind, ComposerBodyKind.json);
      expect(controller.bodyText, contains('"a": 1'));
    });

    test('splits seeded query parameters into editable rows and a clean url',
        () {
      final controller = _controller(
        seed: NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/search?q=phone&page=2'),
        ),
      );

      expect(controller.url, 'https://api.test/search');
      expect(
        {
          for (final row in controller.queryParams) row.key: row.value,
        },
        {'q': 'phone', 'page': '2'},
      );

      final request = controller.buildReplayRequest();
      expect(request!.uri.queryParameters, {'q': 'phone', 'page': '2'});
    });
  });

  group('HttpComposerController.seedFromLog', () {
    test('reconstructs a request from a request log', () {
      final log = ISpectLogData(
        'http',
        key: ISpectLogType.httpRequest.key,
        additionalData: const {
          TraceKeys.meta: {
            'request-data': {
              NetworkJsonKeys.method: 'POST',
              NetworkJsonKeys.url: 'https://api.test/users',
              NetworkJsonKeys.headers: {'Accept': 'application/json'},
              NetworkJsonKeys.data: {'name': 'Ada'},
            },
          },
        },
      );

      final seed = HttpComposerController.seedFromLog(log);

      expect(seed, isNotNull);
      expect(seed!.method, 'POST');
      expect(seed.uri.toString(), 'https://api.test/users');
      expect(seed.body, isA<JsonReplayBody>());
    });

    test('reconstructs from the nested request of a response log', () {
      final log = ISpectLogData(
        'http',
        key: ISpectLogType.httpResponse.key,
        additionalData: const {
          TraceKeys.meta: {
            'response-data': {
              NetworkJsonKeys.request: {
                NetworkJsonKeys.method: 'GET',
                NetworkJsonKeys.url: 'https://api.test/ping',
              },
            },
          },
        },
      );

      final seed = HttpComposerController.seedFromLog(log);

      expect(seed?.method, 'GET');
      expect(seed?.uri.toString(), 'https://api.test/ping');
    });

    test('returns null when the log carries no request data', () {
      final log = ISpectLogData('info', additionalData: const {});

      expect(HttpComposerController.seedFromLog(log), isNull);
    });
  });
}
