import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Map<String, dynamic> body, {
  int statusCode = 200,
}) =>
    ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );

Dio _dioWith(HttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;

void main() {
  group('DioRequestSender.send', () {
    test('returns the response for a successful GET', () async {
      final adapter = _FakeHttpAdapter((_) => _jsonResponse({'ok': true}));
      final sender = DioRequestSender(_dioWith(adapter));

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

    test('encodes a JSON body with the json content-type', () async {
      final adapter = _FakeHttpAdapter((_) => _jsonResponse({'ok': true}));
      final sender = DioRequestSender(_dioWith(adapter));

      await sender.send(
        NetworkReplayRequest(
          method: 'POST',
          uri: Uri.parse('https://api.test/users'),
          body: const JsonReplayBody({'name': 'Ada'}),
        ),
      );

      final captured = adapter.captured!;
      expect(captured.method, 'POST');
      expect(captured.contentType, contains('application/json'));
      expect(captured.data, {'name': 'Ada'});
    });

    test('surfaces a 4xx response via the result instead of throwing',
        () async {
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'error': 'unauthorized'}, statusCode: 401),
      );
      final sender = DioRequestSender(_dioWith(adapter));

      final result = await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/protected'),
        ),
      );

      expect(result.statusCode, 401);
      expect(result.error, isA<DioException>());
      expect((result.body! as Map)['error'], 'unauthorized');
    });

    test('reports a transport failure via result.error with no status',
        () async {
      final adapter =
          _FakeHttpAdapter((_) => throw Exception('connection failed'));
      final sender = DioRequestSender(_dioWith(adapter));

      final result = await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/down'),
        ),
      );

      expect(result.statusCode, isNull);
      expect(result.error, isA<DioException>());
      expect(result.body, isNull);
    });

    test('builds multipart form data from fields and files', () async {
      final adapter = _FakeHttpAdapter((_) => _jsonResponse({'ok': true}));
      final sender = DioRequestSender(_dioWith(adapter));

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

      final data = adapter.captured!.data;
      expect(data, isA<FormData>());
      final form = data as FormData;
      expect(form.fields.single.key, 'title');
      expect(form.fields.single.value, 'photo');
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'a.txt');
    });

    test('the replayed request is logged by the attached interceptor',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final adapter = _FakeHttpAdapter((_) => _jsonResponse({'ok': true}));
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));
      final sender = DioRequestSender(dio);

      await sender.send(
        NetworkReplayRequest(
          method: 'GET',
          uri: Uri.parse('https://api.test/ping'),
        ),
      );

      expect(logger.history, hasLength(2));
      expect(logger.history[0].key, ISpectLogType.httpRequest.key);
      expect(logger.history[1].key, ISpectLogType.httpResponse.key);
    });
  });
}
