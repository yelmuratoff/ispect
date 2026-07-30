import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/http_composer/controllers/http_composer_controller.dart';

class _RecordingSender implements NetworkRequestSender {
  _RecordingSender({
    this.result = const NetworkReplayResult(statusCode: 200),
  });

  final NetworkReplayResult result;
  NetworkReplayRequest? lastRequest;

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async {
    lastRequest = request;
    return result;
  }
}

final class _ThrowingSender implements NetworkRequestSender {
  @override
  String get id => 'throwing';

  @override
  String get label => 'Throwing';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) {
    throw StateError('sender failed');
  }
}

HttpComposerController _controller({
  List<NetworkRequestSender>? senders,
  NetworkReplayRequest? seed,
  DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
}) =>
    HttpComposerController(
      senders: senders ?? [_RecordingSender()],
      seed: seed,
      resourceLimits: resourceLimits,
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

    test('rejects JSON beyond the safe nesting limit before parsing', () {
      const depth = JsonInputPreflight.maxNestingDepth + 1;
      final controller = _controller()
        ..setUrl('https://api.test')
        ..setBodyKind(ComposerBodyKind.json)
        ..setBodyText(
          '${List.filled(depth, '[').join()}0'
          '${List.filled(depth, ']').join()}',
        );

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

    test('retains a detached bounded snapshot of the sender result', () async {
      final headers = <String, String>{'x-request-id': 'req-1'};
      final body = <String, Object?>{
        'message': 'safe',
        'items': <Object?>[1, 2],
      };
      final sender = _RecordingSender(
        result: NetworkReplayResult(
          statusCode: 200,
          headers: headers,
          body: body,
        ),
      );
      final controller = _controller(senders: [sender])
        ..setUrl('https://api.test/ping');

      await controller.send();
      headers['x-request-id'] = 'mutated';
      body['message'] = 'mutated';
      (body['items']! as List<Object?>).add(3);

      final result = controller.result!;
      expect(result.headers, <String, String>{'x-request-id': 'req-1'});
      expect(
        result.body,
        <String, Object?>{
          'message': 'safe',
          'items': <Object?>[1, 2],
        },
      );
      expect(result.headers, isNot(same(headers)));
      expect(result.body, isNot(same(body)));
    });

    test('applies the configured resource limits to response snapshots',
        () async {
      final body = List<String>.filled(10000, 'safe-value').join('|');
      final sender = _RecordingSender(
        result: NetworkReplayResult(body: body),
      );
      final controller = _controller(
        senders: [sender],
        resourceLimits: DiagnosticResourceLimits.constrained,
      )..setUrl('https://api.test/ping');

      await controller.send();

      final resultBody = controller.result!.body! as String;
      expect(
        LogExportOutput.utf8Length(resultBody),
        lessThanOrEqualTo(
          DiagnosticResourceLimits.constrained.maxCapturedValueBytes,
        ),
      );
      expect(resultBody, isNot(body));
    });

    test('resets sending state and captures an unexpected sender failure',
        () async {
      final controller = _controller(senders: [_ThrowingSender()])
        ..setUrl('https://api.test/ping');

      await controller.send();

      expect(controller.isSending, isFalse);
      expect(controller.result, isNotNull);
      expect(controller.result!.isError, isTrue);
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

    test('drops a malformed form body without throwing', () {
      final log = ISpectLogData(
        'http',
        key: ISpectLogType.httpRequest.key,
        additionalData: const {
          TraceKeys.meta: {
            'request-data': {
              NetworkJsonKeys.method: 'POST',
              NetworkJsonKeys.url: 'https://api.test/form',
              NetworkJsonKeys.contentType: 'application/x-www-form-urlencoded',
              NetworkJsonKeys.body: 'safe=value&secret=%ZZ',
            },
          },
        },
      );

      final seed = HttpComposerController.seedFromLog(log);

      expect(seed, isNotNull);
      expect(seed!.body, isNull);
    });

    test('returns null when the log carries no request data', () {
      final log = ISpectLogData('info', additionalData: const {});

      expect(HttpComposerController.seedFromLog(log), isNull);
    });
  });
}
