// Integration tests: Dio interceptor -> ISpectLogger -> history.
//
// Verifies that a full request/response cycle through a real Dio client
// produces the expected records in ISpectLogger.history, including
// correlation IDs and redaction of sensitive headers.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

/// Mimics auth/locale interceptors that rewrite the request via `copyWith`,
/// allocating a fresh [RequestOptions] for everything downstream.
class _CopyOptionsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(
      options.copyWith(headers: {...options.headers, 'X-Test': '1'}),
      handler,
    );
  }
}

/// Minimal in-memory HttpClientAdapter.
///
/// Returns a response built from [handler]. The handler receives the
/// [RequestOptions] so tests can branch on path/method.
class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Map<String, dynamic> body, {
  int statusCode = 200,
  Map<String, List<String>>? headers,
}) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: headers ??
        {
          'content-type': ['application/json'],
        },
  );
}

Dio _dioWith(HttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;

void main() {
  group('Dio integration: interceptor -> logger -> history', () {
    test('successful GET produces request + response records in history',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'ok': true}),
      );
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));

      await dio.get<dynamic>('/users');

      expect(logger.history, hasLength(2));
      final request = logger.history[0];
      final response = logger.history[1];

      expect(request.key, ISpectLogType.httpRequest.key);
      expect(response.key, ISpectLogType.httpResponse.key);

      expect(request.additionalData?[TraceKeys.source], 'dio');
      expect(
        request.additionalData?[TraceKeys.category],
        TraceCategoryIds.network,
      );
      expect(
        response.additionalData?[TraceKeys.category],
        TraceCategoryIds.network,
      );

      // Both records should share the same correlation id.
      final requestCid = request.additionalData?[TraceKeys.correlationId];
      final responseCid = response.additionalData?[TraceKeys.correlationId];
      expect(requestCid, isNotNull);
      expect(responseCid, equals(requestCid));
    });

    test('correlation survives a downstream interceptor that copies options',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'ok': true}),
      );
      // ISpect runs first, so it stores the trace on the pre-copy options.
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger))
        ..interceptors.add(_CopyOptionsInterceptor());

      await dio.get<dynamic>('/users');

      expect(logger.history, hasLength(2));
      final requestCid =
          logger.history[0].additionalData?[TraceKeys.correlationId];
      final responseCid =
          logger.history[1].additionalData?[TraceKeys.correlationId];

      expect(logger.history[1].key, ISpectLogType.httpResponse.key);
      expect(requestCid, isNotNull);
      expect(responseCid, equals(requestCid));
      // Duration rides in extra too, so it survives the copy.
      expect(
        logger.history[1].additionalData?[TraceKeys.durationMs],
        isNotNull,
      );
    });

    test('start stamp is stripped from captured extra; id is preserved',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'ok': true}),
      );
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));

      await dio.get<dynamic>('/users');

      final meta = logger.history[0].additionalData?[TraceKeys.meta] as Map?;
      final requestData = meta?['request-data'] as Map?;
      final extra = requestData?[NetworkJsonKeys.extra] as Map?;
      expect(
        extra?.containsKey(NetworkJsonKeys.ispectRequestStartedAt),
        isFalse,
      );
      expect(extra?[NetworkJsonKeys.ispectRequestId], isNotNull);
    });

    test('4xx response is logged as httpError, not httpResponse', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'error': 'unauthorized'}, statusCode: 401),
      );
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));

      try {
        await dio.get<dynamic>('/protected');
      } on DioException catch (_) {
        // Expected: Dio throws on 4xx by default.
      }

      final errors =
          logger.history.where((r) => r.key == ISpectLogType.httpError.key);
      expect(errors, isNotEmpty);
    });

    test('stream sees the same records that land in history', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final streamed = <ISpectLogData>[];
      final sub = logger.stream.listen(streamed.add);

      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'ok': true}),
      );
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));

      await dio.get<dynamic>('/ping');
      await Future<void>.delayed(Duration.zero);

      expect(
        streamed.map((d) => d.key).toList(),
        equals(logger.history.map((d) => d.key).toList()),
      );

      await sub.cancel();
    });

    test('bounded history evicts oldest entries beyond maxHistoryItems',
        () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
          maxHistoryItems: 2,
        ),
      );
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'ok': true}),
      );
      final dio = _dioWith(adapter)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));

      // 3 requests × 2 entries each = 6 entries, history capped at 2.
      await dio.get<dynamic>('/a');
      await dio.get<dynamic>('/b');
      await dio.get<dynamic>('/c');

      expect(logger.history, hasLength(2));
      // The last two entries should be the response for /c and the request
      // for /c (or the request and response of /c). Regardless of order,
      // both must belong to /c because earlier entries were evicted.
      final targets =
          logger.history.map((d) => d.additionalData?[TraceKeys.target] ?? '');
      for (final target in targets) {
        expect(target.toString(), contains('/c'));
      }
    });
  });

  group('Dio integration: redaction', () {
    test('Authorization header is redacted in history records', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final adapter = _FakeHttpAdapter(
        (_) => _jsonResponse({'ok': true}),
      );
      final dio = _dioWith(adapter)
        ..interceptors.add(
          ISpectDioInterceptor(
            logger: logger,
            settings: const ISpectDioInterceptorSettings(
              printRequestHeaders: true,
            ),
          ),
        );

      const secret = 'Bearer super-secret-token-xyz';
      await dio.get<dynamic>(
        '/me',
        options: Options(headers: {'Authorization': secret}),
      );

      final request = logger.history
          .firstWhere((r) => r.key == ISpectLogType.httpRequest.key);

      // The raw secret must not appear anywhere in the serialized record.
      final serialized = jsonEncode(_stringify(request.additionalData));
      expect(
        serialized.contains('super-secret-token-xyz'),
        isFalse,
        reason: 'Raw Authorization token must not leak into history',
      );
    });
  });
}

// Converts non-encodable values to strings so the whole tree can be JSON
// encoded for assertion scanning.
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
