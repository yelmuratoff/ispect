// Integration tests: HTTP interceptor -> ISpectLogger -> history.
//
// Drives a real `InterceptedClient` with a `MockClient` backend so the full
// interceptor pipeline runs end-to-end: request logging, response logging,
// correlation IDs, and redaction of sensitive headers.

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
      // `response.request` may be a wrapped BaseRequest inside
      // InterceptedClient, so the Expando-based correlation id may or may
      // not propagate. If it does, it must match the request id.
      final responseCid = response.additionalData?[TraceKeys.correlationId];
      if (responseCid != null) {
        expect(responseCid, equals(requestCid));
      }
    });

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
}

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
