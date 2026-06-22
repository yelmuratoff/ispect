import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

void main() {
  group('HttpClientRequestSender.send', () {
    test('returns the response for a successful GET', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'ok': true}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final sender = HttpClientRequestSender(client);

      final result = await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/users'),
        ),
      );

      expect(result.statusCode, 200);
      expect(result.error, isNull);
      expect((result.body! as Map)['ok'], true);
    });

    test('returns a 4xx response without an error (http does not throw)',
        () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'error': 'missing'}), 404),
      );
      final sender = HttpClientRequestSender(client);

      final result = await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/missing'),
        ),
      );

      expect(result.statusCode, 404);
      expect(result.error, isNull);
      expect((result.body! as Map)['error'], 'missing');
    });

    test('reports a transport failure via result.error with no status',
        () async {
      final client = MockClient(
        (_) async => throw http.ClientException('connection failed'),
      );
      final sender = HttpClientRequestSender(client);

      final result = await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/down'),
        ),
      );

      expect(result.statusCode, isNull);
      expect(result.error, isA<http.ClientException>());
      expect(result.body, isNull);
    });

    test('encodes a JSON body with the json content-type', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      });
      final sender = HttpClientRequestSender(client);

      await sender.send(
        NetworkReplayRequest(
          method: 'POST',
          uri: Uri.parse('https://api.test/users'),
          body: const JsonReplayBody({'name': 'Ada'}),
        ),
      );

      expect(captured.method, 'POST');
      expect(captured.headers['content-type'], contains('application/json'));
      expect(jsonDecode(captured.body), {'name': 'Ada'});
    });

    test('builds a multipart request from fields and files', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      });
      final sender = HttpClientRequestSender(client);

      await sender.send(
        NetworkReplayRequest(
          method: 'POST',
          uri: Uri.parse('https://api.test/upload'),
          body: const MultipartReplayBody(
            fields: [MultipartReplayField('title', 'photo')],
            files: [
              MultipartReplayFile(
                field: 'file',
                file: ComposerPickedFile(
                  filename: 'a.txt',
                  bytes: [104, 105],
                  contentType: 'text/plain',
                ),
              ),
            ],
          ),
        ),
      );

      expect(captured.headers['content-type'], contains('multipart/form-data'));
      expect(captured.body, contains('photo'));
      expect(captured.body, contains('a.txt'));
    });

    test('the replayed request is logged by the attached interceptor',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = InterceptedClient.build(
        interceptors: [ISpectHttpInterceptor(logger: logger)],
        client: MockClient(
          (_) async => http.Response(jsonEncode({'ok': true}), 200),
        ),
      );
      final sender = HttpClientRequestSender(client);

      await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/ping'),
        ),
      );
      client.close();

      expect(logger.history, hasLength(2));
      expect(logger.history[0].key, ISpectLogType.httpRequest.key);
      expect(logger.history[1].key, ISpectLogType.httpResponse.key);
    });
  });
}
