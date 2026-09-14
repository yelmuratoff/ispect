import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

Map<String, dynamic> _meta(ISpectLogData log) =>
    log.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

final class _ThrowingBodyResponse extends http.Response {
  _ThrowingBodyResponse(
    int statusCode, {
    required http.BaseRequest request,
  }) : super('', statusCode, request: request);

  int bodyReads = 0;

  @override
  String get body {
    bodyReads++;
    throw StateError('response body must not be decoded');
  }
}

final class _CountingBodyResponse extends http.Response {
  _CountingBodyResponse(
    super.body,
    super.statusCode, {
    required super.request,
    super.headers = const {},
  });

  int bodyReads = 0;

  @override
  String get body {
    bodyReads++;
    return super.body;
  }
}

final class _ThrowingLengthMultipartRequest extends http.MultipartRequest {
  _ThrowingLengthMultipartRequest(super.method, super.url);

  int contentLengthReads = 0;

  @override
  int get contentLength {
    contentLengthReads++;
    throw StateError('multipart length must not be calculated for logging');
  }
}

final class _HostileUri implements Uri {
  int pathCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    return Uri.parse('https://spoofed.example.test').runtimeType;
  }

  @override
  String get path {
    pathCalls++;
    throw StateError('hostile path');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('hostile formatter');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('hostile Uri member');
}

void main() {
  group('HTTP security regressions', () {
    test('hostile Uri capture stays opaque without aborting interception',
        () async {
      final uri = _HostileUri();
      final request = http.Request('GET', uri);
      final response = http.Response('', 200, request: request);
      final requestJson = HttpRequestData(request).toJson(
        captureMode: DiagnosticCaptureMode.strict,
      );
      final responseJson = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      ).toJson(captureMode: DiagnosticCaptureMode.strict);

      expect(
        requestJson[NetworkJsonKeys.url],
        JsonValueNormalizer.unprintableValue,
      );
      expect(
        responseJson[NetworkJsonKeys.url],
        JsonValueNormalizer.unprintableValue,
      );
      expect(
        (responseJson[NetworkJsonKeys.request] as Map)[NetworkJsonKeys.url],
        JsonValueNormalizer.unprintableValue,
      );

      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );

      expect(
        await interceptor.interceptRequest(request: request),
        same(request),
      );
      expect(
        await interceptor.interceptResponse(response: response),
        same(response),
      );
      expect(logger.history, hasLength(2));
      expect(uri.toStringCalls, 0);
      expect(uri.pathCalls, 0);
      expect(uri.runtimeTypeCalls, 0);
    });

    for (final statusCode in const [200, 500]) {
      test(
        'does not decode a $statusCode response body when capture is disabled',
        () async {
          final request = http.Request(
            'GET',
            Uri.parse('https://api.example.com/request'),
          );
          final response = _ThrowingBodyResponse(
            statusCode,
            request: request,
          );
          final interceptor = ISpectHttpInterceptor(
            logger: ISpectLogger(
              options: ISpectLoggerOptions(useConsoleLogs: false),
            ),
            settings: const ISpectHttpInterceptorSettings(
              logRequests: false,
              printResponseData: false,
              printErrorData: false,
            ),
          );

          await interceptor.interceptResponse(response: response);

          expect(response.bodyReads, 0);
        },
      );
    }

    test('decodes an enabled response from bounded bytes without reading body',
        () async {
      final request = http.Request(
        'GET',
        Uri.parse('https://api.example.com/request'),
      );
      final response = _CountingBodyResponse(
        '{"ok":true}',
        200,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      await ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          logRequests: false,
          printResponseData: true,
        ),
      ).interceptResponse(response: response);

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData] as Map;
      expect(response.bodyReads, 0);
      expect(responseData[NetworkJsonKeys.body], {'ok': true});
    });

    test('malformed request charset fails closed without breaking interception',
        () async {
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/request'),
      )
        ..bodyBytes = utf8.encode('{"password":"secret"}')
        ..headers['content-type'] =
            'application/json; charset=unknown-ispect-charset';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      final returned = await ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(printRequestData: true),
      ).interceptRequest(request: request);

      final requestData =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      expect(returned, same(request));
      expect(
        requestData[NetworkJsonKeys.data],
        LogExportOutput.truncatedMarker,
      );
    });

    for (final bodyCase in const ['malformed-charset', 'malformed-utf8']) {
      test('$bodyCase response fails closed without breaking interception',
          () async {
        final request = http.Request(
          'GET',
          Uri.parse('https://api.example.com/request'),
        );
        final headers = bodyCase == 'malformed-charset'
            ? const {
                'content-type':
                    'application/json; charset=unknown-ispect-charset',
              }
            : const {'content-type': 'application/json; charset=utf-8'};
        final response = http.Response.bytes(
          bodyCase == 'malformed-charset'
              ? utf8.encode('{"ok":true}')
              : const [0xc3, 0x28],
          200,
          request: request,
          headers: headers,
        );
        final logger = ISpectLogger(
          options: ISpectLoggerOptions(useConsoleLogs: false),
        );

        final returned = await ISpectHttpInterceptor(
          logger: logger,
          settings: const ISpectHttpInterceptorSettings(
            logRequests: false,
            printResponseData: true,
          ),
        ).interceptResponse(response: response);

        final responseData =
            _meta(logger.history.single)[NetworkJsonKeys.responseData] as Map;
        expect(returned, same(response));
        expect(
          responseData[NetworkJsonKeys.body],
          LogExportOutput.truncatedMarker,
        );
      });
    }

    for (final statusCode in const [200, 500]) {
      test(
        'multipart fields obey request capture for a $statusCode response',
        () async {
          final logger = ISpectLogger(
            options: ISpectLoggerOptions(useConsoleLogs: false),
          );
          final interceptor = ISpectHttpInterceptor(
            logger: logger,
            settings: const ISpectHttpInterceptorSettings(
              logRequests: false,
              printRequestData: false,
              printResponseData: true,
              printErrorData: true,
            ),
          );
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('https://api.example.com/upload'),
          )..fields['password'] = 'multipart-secret';

          await interceptor.interceptRequest(request: request);
          await interceptor.interceptResponse(
            response: http.StreamedResponse(
              const Stream<List<int>>.empty(),
              statusCode,
              request: request,
            ),
          );

          final payloadKey = statusCode >= 400
              ? NetworkJsonKeys.errorData
              : NetworkJsonKeys.responseData;
          final responseData = _meta(logger.history.single)[payloadKey] as Map;
          expect(
            responseData.containsKey(NetworkJsonKeys.multipartRequest),
            isFalse,
          );
        },
      );
    }

    test('redacts sensitive keys in a JSON-encoded request body', () {
      const secret = 'HTTP-JSON-STRING-SECRET';
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/login'),
      )..body = '{"username":"ada","password":"$secret"}';
      final data = HttpRequestData(request).toJson();

      HttpRequestData.redact(data, RedactionService());

      expect(data[NetworkJsonKeys.data], isA<String>());
      expect(data[NetworkJsonKeys.data], isNot(contains(secret)));
    });

    test('scrubs malformed JSON with configured sensitive keys', () {
      const secret = 'HTTP-MALFORMED-CUSTOM-SECRET';
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/login'),
      )..body = '{"tenantSecret":"$secret",}';
      final data = HttpRequestData(request).toJson();

      HttpRequestData.redact(
        data,
        RedactionService(sensitiveKeys: {'tenantSecret'}),
      );

      expect(data[NetworkJsonKeys.data], isA<String>());
      expect(data[NetworkJsonKeys.data], isNot(contains(secret)));
    });

    test('scrubs malformed JSON response bodies', () async {
      const secret = 'HTTP-MALFORMED-RESPONSE-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printResponseData: true,
        ),
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      );

      await interceptor.interceptResponse(
        response: http.Response(
          '{"tenantSecret":"$secret",}',
          200,
          request: http.Request(
            'GET',
            Uri.parse('https://api.example.com/request'),
          ),
        ),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData]
              as Map<String, dynamic>;
      expect(responseData[NetworkJsonKeys.body], isNot(contains(secret)));
    });

    test('disabled request and response fields are not retained', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: false,
          printRequestHeaders: false,
          printResponseData: false,
          printResponseHeaders: false,
          printResponseMessage: false,
        ),
      );
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/users'),
      )
        ..body = '{"password":"request-secret"}'
        ..headers['Authorization'] = 'Bearer request-token';

      await interceptor.interceptRequest(request: request);
      await interceptor.interceptResponse(
        response: http.Response(
          '{"password":"response-secret"}',
          200,
          reasonPhrase: 'response-message',
          headers: {'Authorization': 'Bearer response-token'},
          request: request,
        ),
      );

      final requestData =
          _meta(logger.history[0])[NetworkJsonKeys.requestData] as Map;
      expect(requestData.containsKey(NetworkJsonKeys.data), isFalse);
      expect(requestData.containsKey(NetworkJsonKeys.headers), isFalse);

      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData.containsKey(NetworkJsonKeys.body), isFalse);
      expect(responseData.containsKey(NetworkJsonKeys.headers), isFalse);
      expect(responseData.containsKey(NetworkJsonKeys.statusMessage), isFalse);
      final nestedRequest = responseData[NetworkJsonKeys.request] as Map;
      expect(nestedRequest.containsKey(NetworkJsonKeys.data), isFalse);
      expect(nestedRequest.containsKey(NetworkJsonKeys.headers), isFalse);
    });

    test('production settings retain only an error record', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: ISpectHttpInterceptorSettingsBuilder.production().build(),
      );
      final successRequest = http.Request(
        'GET',
        Uri.parse('https://api.example.com/success'),
      );

      await interceptor.interceptRequest(request: successRequest);
      await interceptor.interceptResponse(
        response: http.Response('', 200, request: successRequest),
      );

      expect(logger.history, isEmpty);

      final errorRequest = http.Request(
        'GET',
        Uri.parse('https://api.example.com/failure'),
      );
      await interceptor.interceptRequest(request: errorRequest);
      await interceptor.interceptResponse(
        response: http.Response(
          '{"error":"failed"}',
          500,
          request: errorRequest,
        ),
      );

      expect(logger.history, hasLength(1));
      expect(logger.history.single.key, ISpectLogType.httpError.key);
      expect(
        logger.history.single.additionalData?[TraceKeys.correlationId],
        isNotNull,
      );
    });

    test('disabled error fields are not retained', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          logRequests: false,
          printRequestData: false,
          printRequestHeaders: false,
          printErrorData: false,
          printErrorHeaders: false,
          printErrorMessage: false,
        ),
      );
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/failure'),
      )
        ..body = '{"password":"request-secret"}'
        ..headers['Authorization'] = 'Bearer request-token';

      await interceptor.interceptRequest(request: request);
      await interceptor.interceptResponse(
        response: http.Response(
          '{"password":"response-secret"}',
          500,
          reasonPhrase: 'response-message',
          headers: {'Authorization': 'Bearer response-token'},
          request: request,
        ),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.errorData] as Map;
      expect(responseData.containsKey(NetworkJsonKeys.body), isFalse);
      expect(responseData.containsKey(NetworkJsonKeys.headers), isFalse);
      expect(responseData.containsKey(NetworkJsonKeys.statusMessage), isFalse);
      final nestedRequest = responseData[NetworkJsonKeys.request] as Map;
      expect(nestedRequest.containsKey(NetworkJsonKeys.data), isFalse);
      expect(nestedRequest.containsKey(NetworkJsonKeys.headers), isFalse);
    });

    test('redacts server-controlled reason phrases', () async {
      const secret = 'HTTP-REASON-PHRASE-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      );
      final request = http.Request(
        'GET',
        Uri.parse('https://api.example.com/request'),
      );

      await interceptor.interceptResponse(
        response: http.Response(
          '',
          200,
          reasonPhrase: 'upstream {"tenantSecret":"$secret"}',
          request: request,
        ),
      );

      final log = logger.history.single;
      final responseData =
          _meta(log)[NetworkJsonKeys.responseData] as Map<String, dynamic>;
      expect(
        responseData[NetworkJsonKeys.statusMessage],
        isNot(contains(secret)),
      );
      expect(log.textMessage, isNot(contains(secret)));
    });

    test('redaction opt-out preserves server-controlled reason phrases',
        () async {
      const secret = 'HTTP-RAW-REASON-PHRASE-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(enableRedaction: false),
      );
      final request = http.Request(
        'GET',
        Uri.parse('https://api.example.com/request'),
      );

      await interceptor.interceptResponse(
        response: http.Response(
          '',
          200,
          reasonPhrase: 'upstream {"tenantSecret":"$secret"}',
          request: request,
        ),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData]
              as Map<String, dynamic>;
      expect(
        responseData[NetworkJsonKeys.statusMessage],
        contains(secret),
      );
    });

    test('redaction opt-out preserves a JSON-encoded request body', () async {
      const secret = 'HTTP-RAW-JSON-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          enableRedaction: false,
          printRequestData: true,
        ),
      );
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/login'),
      )..body = '{"password":"$secret"}';

      await interceptor.interceptRequest(request: request);

      expect(jsonEncode(_meta(logger.history.single)), contains(secret));
    });

    test('redaction opt-out preserves malformed and bounds oversized bodies',
        () async {
      const malformed = '{"tenantSecret":"HTTP-RAW-MALFORMED-SECRET",}';
      final oversized = '"${List.filled(1024 * 1024, 'x').join()}"';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          enableRedaction: false,
          printResponseData: true,
        ),
      );

      for (final body in [malformed, oversized]) {
        await interceptor.interceptResponse(
          response: http.Response(
            body,
            200,
            request: http.Request(
              'GET',
              Uri.parse('https://api.example.com/request'),
            ),
          ),
        );
      }

      final capturedBodies = logger.history
          .map(
            (log) => (_meta(log)[NetworkJsonKeys.responseData]
                as Map<String, dynamic>)[NetworkJsonKeys.body],
          )
          .toList();
      expect(capturedBodies.first, malformed);
      final bounded = capturedBodies.last as String;
      expect(bounded, startsWith('"xxx'));
      expect(bounded, endsWith(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(bounded),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('active redaction replaces oversized request and response bodies',
        () async {
      final huge =
          utf8.encode('ACTIVE_HTTP_BODY_SECRET_${'x' * (1024 * 1024)}');
      final request = http.Request(
        'POST',
        Uri.parse('https://api.example.com/request'),
      )..bodyBytes = huge;
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: true,
          printResponseData: true,
        ),
      );

      await interceptor.interceptRequest(request: request);
      await interceptor.interceptResponse(
        response: http.Response.bytes(huge, 200, request: request),
      );

      final requestData =
          _meta(logger.history.first)[NetworkJsonKeys.requestData] as Map;
      final responseData =
          _meta(logger.history.last)[NetworkJsonKeys.responseData] as Map;
      expect(
        requestData[NetworkJsonKeys.data],
        LogExportOutput.truncatedMarker,
      );
      expect(
        responseData[NetworkJsonKeys.body],
        LogExportOutput.truncatedMarker,
      );
    });

    test('multipart fields and files stop at bounded collection budgets', () {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.example.com/upload'),
      );
      for (var index = 0;
          index < JsonValueNormalizer.defaultMaxCollectionItems + 100;
          index++) {
        request.fields['field-$index'] = 'value-$index';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file-$index',
            const [],
            filename: 'file-$index.txt',
          ),
        );
      }
      final responseData = HttpResponseData(
        response: null,
        baseResponse: http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          request: request,
        ),
        requestData: HttpRequestData(request),
        multipartRequest: request,
      ).toJson(redactionActive: true);

      final multipart = responseData[NetworkJsonKeys.multipartRequest] as Map;
      final encoded = jsonEncode(multipart);
      expect(encoded, contains(JsonValueNormalizer.maxCollectionItemsReached));
      expect(
        LogExportOutput.utf8Length(encoded),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('multipart capture does not calculate an unbounded content length',
        () async {
      final request = _ThrowingLengthMultipartRequest(
        'POST',
        Uri.parse('https://api.example.com/upload'),
      )..fields['field'] = 'value';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      final returned = await ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: true,
        ),
      ).interceptRequest(request: request);

      final requestData =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      expect(returned, same(request));
      expect(request.contentLengthReads, 0);
      expect(requestData[NetworkJsonKeys.contentLength], isNull);
    });
  });
}
