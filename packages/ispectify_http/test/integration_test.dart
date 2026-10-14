// Integration tests: HTTP interceptor -> ISpectLogger -> history.
//
// Drives a real `InterceptedClient` with a `MockClient` backend so the full
// interceptor pipeline runs end-to-end: request logging, response logging,
// correlation IDs, and redaction of sensitive headers.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

http.Client _mockJson(
  Map<String, dynamic> body, {
  int statusCode = 200,
}) =>
    MockClient(
      (request) async => http.Response(
        jsonEncode(body),
        statusCode,
        headers: {'content-type': 'application/json'},
        request: request,
      ),
    );

InterceptedClient _clientWith(ISpectLogger logger, {http.Client? inner}) =>
    InterceptedClient.build(
      interceptors: [ISpectHttpInterceptor(logger: logger)],
      client: inner ?? _mockJson({'ok': true}),
    );

void main() {
  group('HTTP integration: interceptor -> logger -> history', () {
    test('successful GET produces request + response records', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(logger);

      await client.get(Uri.parse('https://api.test/users'));
      client.close();

      expect(logger.history, hasLength(2));
      final request = logger.history[0];
      final response = logger.history[1];

      expect(request.key, ISpectLogType.httpRequest.key);
      expect(response.key, ISpectLogType.httpResponse.key);

      expect(request.additionalData?[TraceKeys.source], 'http');
      expect(
        request.additionalData?[TraceKeys.category],
        TraceCategoryIds.network,
      );

      // The request side must always carry a correlation id.
      final requestCid = request.additionalData?[TraceKeys.correlationId];
      expect(requestCid, isA<String>());
    });

    for (final statusCode in [200, 500]) {
      test('response $statusCode shares the request correlation id and timing',
          () async {
        final logger = ISpectLogger(
          options: ISpectLoggerOptions(useConsoleLogs: false),
        );
        final client = _clientWith(
          logger,
          inner: MockClient.streaming(
            (request, _) async => http.StreamedResponse(
              Stream.value(utf8.encode('{"ok":true}')),
              statusCode,
              request: request,
            ),
          ),
        );

        await client.get(Uri.parse('https://api.test/users'));
        client.close();

        expect(logger.history, hasLength(2));
        final requestCid =
            logger.history[0].additionalData?[TraceKeys.correlationId];
        final responseData = logger.history[1].additionalData;
        expect(requestCid, isA<String>());
        expect(responseData?[TraceKeys.correlationId], requestCid);
        expect(responseData?[TraceKeys.durationMs], isA<int>());
      });
    }

    test('request and response console URLs show redacted query parameters',
        () async {
      const secret = 'HTTP-QUERY-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(logger);

      await client.get(
        Uri.parse(
          'https://api.test/users?page=2&token=$secret',
        ),
      );
      client.close();

      expect(logger.history, hasLength(2));
      for (final entry in logger.history) {
        final output = const HumanLogEntryFormatter().format(
          entry,
          ConsoleSettings(enableColors: false),
        );
        final serialized = jsonEncode(_stringify(entry.additionalData));
        expect(output, contains('?page=2&token=[REDACTED]'));
        expect(output, isNot(contains('Query Parameters:')));
        expect(output, isNot(contains(secret)));
        expect(serialized, isNot(contains(secret)));
      }
    });

    test('5xx response is logged as httpError', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(
        logger,
        inner: _mockJson({'error': 'server'}, statusCode: 500),
      );

      await client.get(Uri.parse('https://api.test/bad'));
      client.close();

      final errors =
          logger.history.where((r) => r.key == ISpectLogType.httpError.key);
      expect(errors, isNotEmpty);
    });

    test('error console URL shows the request query parameters', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(
        logger,
        inner: _mockJson({'error': 'server'}, statusCode: 500),
      );

      await client.get(
        Uri.parse('https://api.test/failure?retry=true'),
      );
      client.close();

      final error = logger.history
          .firstWhere((entry) => entry.key == ISpectLogType.httpError.key);
      final output = const HumanLogEntryFormatter().format(
        error,
        ConsoleSettings(enableColors: false),
      );
      expect(
        output,
        allOf(contains('?retry=true'), isNot(contains('Query Parameters:'))),
      );
    });

    test('stream and history stay in sync', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final streamed = <ISpectLogData>[];
      final sub = logger.stream.listen(streamed.add);

      final client = _clientWith(logger);
      await client.get(Uri.parse('https://api.test/ping'));
      client.close();
      await Future<void>.delayed(Duration.zero);

      expect(
        streamed.map((d) => d.key).toList(),
        equals(logger.history.map((d) => d.key).toList()),
      );

      await sub.cancel();
    });
  });

  group('HTTP integration: redaction', () {
    test('Authorization header is redacted in history', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = InterceptedClient.build(
        interceptors: [
          ISpectHttpInterceptor(
            logger: logger,
            settings: const ISpectHttpInterceptorSettings(
              printRequestHeaders: true,
            ),
          ),
        ],
        client: _mockJson({'ok': true}),
      );

      const secret = 'Bearer super-secret-http-token-xyz';
      await client.get(
        Uri.parse('https://api.test/me'),
        headers: {'Authorization': secret},
      );
      client.close();

      final request = logger.history
          .firstWhere((r) => r.key == ISpectLogType.httpRequest.key);

      final serialized = jsonEncode(_stringify(request.additionalData));
      expect(
        serialized.contains('super-secret-http-token-xyz'),
        isFalse,
        reason: 'Raw Authorization token must not leak into history',
      );
    });

    test('explicit opt-out preserves raw query parameters in history',
        () async {
      const secret = 'HTTP-RAW-QUERY-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = InterceptedClient.build(
        interceptors: [
          ISpectHttpInterceptor(
            logger: logger,
            settings: const ISpectHttpInterceptorSettings(
              enableRedaction: false,
            ),
          ),
        ],
        client: _mockJson({'ok': true}),
      );

      await client.get(
        Uri.parse('https://api.test/me?token=$secret'),
      );
      client.close();

      final request = logger.history
          .firstWhere((entry) => entry.key == ISpectLogType.httpRequest.key);
      final meta = request.additionalData?[TraceKeys.meta] as Map;
      final requestData = meta[NetworkJsonKeys.requestData] as Map;
      final query = requestData[NetworkJsonKeys.queryParameters] as Map;
      expect(query['token'], secret);
    });
  });

  group('HTTP integration: response body capture', () {
    test('send returns before the body is read and captures it on read',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      final client = _clientWith(
        logger,
        inner: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            contentLength: 11,
            request: request,
          ),
        ),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/slow')),
      );

      expect(source.hasListener, isFalse);
      expect(logger.history, hasLength(1));

      final chunks = <List<int>>[];
      final done = response.stream.listen(chunks.add).asFuture<void>();
      source.add(utf8.encode('{"ok":'));
      await pumpEventQueue();
      expect(chunks, hasLength(1));
      source.add(utf8.encode('true}'));
      await source.close();
      await done;
      client.close();

      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData[NetworkJsonKeys.body], {'ok': true});
    });

    test('keeps the post-redirect url of the inner response', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final finalUrl = Uri.parse('https://api.test/final');
      final client = _clientWith(
        logger,
        inner: _RedirectedClient(finalUrl),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/start')),
      );
      await response.stream.drain<void>();
      client.close();

      expect(response, isA<http.BaseResponseWithUrl>());
      expect((response as http.BaseResponseWithUrl).url, finalUrl);
    });

    test('a cancelled read logs the response without a body', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      addTearDown(() => unawaited(source.close()));
      final client = _clientWith(
        logger,
        inner: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            contentLength: 4,
            request: request,
          ),
        ),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/a')),
      );
      final subscription = response.stream.listen((_) {});
      source.add(utf8.encode('ab'));
      await pumpEventQueue();
      await subscription.cancel();
      client.close();

      expect(logger.history, hasLength(2));
      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData[NetworkJsonKeys.body], isNull);
    });

    test('logs an unread response once, without its body', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(
        logger,
        inner: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            Stream.value(utf8.encode('{"ok":true}')),
            200,
            contentLength: 11,
            request: request,
          ),
        ),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/a')),
      );
      await pumpEventQueue();

      expect(response.statusCode, 200);
      expect(logger.history, hasLength(2));
      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData[NetworkJsonKeys.body], isNull);

      expect(
        utf8.decode(await response.stream.toBytes()),
        '{"ok":true}',
      );
      client.close();

      expect(logger.history, hasLength(2));
    });

    test('success body reaches history through InterceptedClient', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(logger, inner: _mockJson({'ok': true}));

      final response = await client.get(Uri.parse('https://api.test/users'));
      client.close();

      expect(jsonDecode(response.body), {'ok': true});
      final meta = _meta(logger.history[1]);
      final responseData = meta[NetworkJsonKeys.responseData] as Map;
      expect(responseData[NetworkJsonKeys.body], {'ok': true});
    });

    test('error body reaches history through InterceptedClient', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final client = _clientWith(
        logger,
        inner: _mockJson({'error': 'server'}, statusCode: 500),
      );

      final response = await client.get(Uri.parse('https://api.test/bad'));
      client.close();

      expect(jsonDecode(response.body), {'error': 'server'});
      final error = logger.history
          .firstWhere((entry) => entry.key == ISpectLogType.httpError.key);
      final errorData = _meta(error)[NetworkJsonKeys.errorData] as Map;
      expect(errorData[NetworkJsonKeys.body], {'error': 'server'});
    });

    test('buffered response hands the consumer identical bytes and metadata',
        () async {
      final bytes = utf8.encode('{"ok":true}');
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      late http.BaseRequest sent;
      final client = _clientWith(
        logger,
        inner: MockClient.streaming((request, _) async {
          sent = request;
          return http.StreamedResponse(
            source.stream,
            201,
            contentLength: bytes.length,
            request: request,
            headers: {'content-type': 'application/json', 'x-trace': 'abc'},
            isRedirect: true,
            persistentConnection: false,
            reasonPhrase: 'Created',
          );
        }),
      );
      source
        ..add(bytes.sublist(0, 4))
        ..add(bytes.sublist(4));
      unawaited(source.close());

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/users')),
      );
      final received = await response.stream.toBytes();
      client.close();

      expect(received, bytes);
      expect(response.statusCode, 201);
      expect(response.contentLength, bytes.length);
      expect(response.request, same(sent));
      expect(response.headers, {
        'content-type': 'application/json',
        'x-trace': 'abc',
      });
      expect(response.isRedirect, isTrue);
      expect(response.persistentConnection, isFalse);
      expect(response.reasonPhrase, 'Created');
      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData[NetworkJsonKeys.body], {'ok': true});
    });

    test('stream failure while buffering surfaces to the body consumer',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final failure = http.ClientException('connection reset');
      final source = StreamController<List<int>>()
        ..add(utf8.encode('par'))
        ..addError(failure);
      unawaited(source.close());
      final client = _clientWith(
        logger,
        inner: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            contentLength: 8,
            request: request,
          ),
        ),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/reset')),
      );
      final received = <int>[];
      final read = response.stream.listen(received.addAll).asFuture<void>();
      client.close();

      await expectLater(read, throwsA(same(failure)));
      expect(utf8.decode(received), 'par');
      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData.containsKey(NetworkJsonKeys.body), isFalse);
    });

    test('unknown-length stream passes through without buffering', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      final client = _clientWith(
        logger,
        inner: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            request: request,
          ),
        ),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/events')),
      );

      expect(source.hasListener, isFalse);
      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData.containsKey(NetworkJsonKeys.body), isFalse);

      final received = response.stream.toBytes();
      source
        ..add(utf8.encode('chunk-1;'))
        ..add(utf8.encode('chunk-2'));
      await source.close();
      expect(utf8.decode(await received), 'chunk-1;chunk-2');
      client.close();
    });

    test('known-length body above the byte budget is not buffered', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      final body = List<int>.filled(17, 0x61);
      final client = InterceptedClient.build(
        interceptors: [
          ISpectHttpInterceptor(
            logger: logger,
            settings: const ISpectHttpInterceptorSettings(
              resourceLimits: DiagnosticResourceLimits(maxNetworkBodyBytes: 16),
            ),
          ),
        ],
        client: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            contentLength: body.length,
            request: request,
          ),
        ),
      );

      final response = await client.send(
        http.Request('GET', Uri.parse('https://api.test/large')),
      );

      expect(source.hasListener, isFalse);
      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(
        responseData[NetworkJsonKeys.body],
        LogExportOutput.truncatedMarker,
      );
      expect(responseData[NetworkJsonKeys.bodyBytes], '17');

      final received = response.stream.toBytes();
      source.add(body);
      await source.close();
      expect(await received, body);
      client.close();
    });

    test('body capture disabled leaves the stream unbuffered', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      addTearDown(() => unawaited(source.close()));
      final client = InterceptedClient.build(
        interceptors: [
          ISpectHttpInterceptor(
            logger: logger,
            settings: const ISpectHttpInterceptorSettings(
              printResponseData: false,
            ),
          ),
        ],
        client: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            contentLength: 2,
            request: request,
          ),
        ),
      );

      await client.send(http.Request('GET', Uri.parse('https://api.test/a')));
      client.close();

      expect(source.hasListener, isFalse);
      expect(logger.history, hasLength(2));
    });

    test('unlogged success responses leave the stream unbuffered', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      addTearDown(() => unawaited(source.close()));
      final client = InterceptedClient.build(
        interceptors: [
          ISpectHttpInterceptor(
            logger: logger,
            settings: const ISpectHttpInterceptorSettings(
              logResponses: false,
            ),
          ),
        ],
        client: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            200,
            contentLength: 2,
            request: request,
          ),
        ),
      );

      await client.send(http.Request('GET', Uri.parse('https://api.test/a')));
      client.close();

      expect(source.hasListener, isFalse);
    });

    test('disabled logger leaves the stream unbuffered', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(enabled: false, useConsoleLogs: false),
      );
      final source = StreamController<List<int>>();
      addTearDown(() => unawaited(source.close()));
      final client = _clientWith(
        logger,
        inner: MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            source.stream,
            500,
            contentLength: 2,
            request: request,
          ),
        ),
      );

      await client.send(http.Request('GET', Uri.parse('https://api.test/a')));
      client.close();

      expect(source.hasListener, isFalse);
      expect(logger.history, isEmpty);
    });
  });
}

Map<String, dynamic> _meta(ISpectLogData entry) =>
    entry.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

Object? _stringify(Object? value) {
  if (value == null) return null;
  if (value is Map) {
    return value.map<String, Object?>(
      (k, v) => MapEntry(k.toString(), _stringify(v)),
    );
  }
  if (value is Iterable) {
    return value.map<Object?>(_stringify).toList();
  }
  if (value is num || value is bool || value is String) return value;
  return value.toString();
}

final class _UrlStreamedResponse extends http.StreamedResponse
    implements http.BaseResponseWithUrl {
  _UrlStreamedResponse(
    super.stream,
    super.statusCode, {
    required this.url,
    super.contentLength,
    super.request,
  });

  @override
  final Uri url;
}

final class _RedirectedClient extends http.BaseClient {
  _RedirectedClient(this.finalUrl);

  final Uri finalUrl;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    return _UrlStreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
      contentLength: 2,
      request: request,
      url: finalUrl,
    );
  }
}
