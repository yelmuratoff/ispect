// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:ispectify_http/src/settings.dart';
import 'package:test/test.dart';

void main() {
  group('HttpResponseLog', () {
    test('textMessage uses responseBody, not requestBody', () {
      const settings = ISpectHttpInterceptorSettings(
        printResponseMessage: false,
      );

      final log = HttpResponseLog(
        'https://example.com',
        method: 'GET',
        url: 'https://example.com',
        path: '/path',
        statusCode: 200,
        statusMessage: 'OK',
        requestHeaders: null,
        headers: null,
        requestBody: const {'shouldNotAppear': true},
        responseBody: const {'hello': 'world'},
        settings: settings,
        responseData: null,
      );

      final text = log.textMessage;
      expect(
        text.contains('hello'),
        isTrue,
        reason: 'Response body should be present in output',
      );
      expect(
        text.contains('shouldNotAppear'),
        isFalse,
        reason: 'Request body must not be shown in response log',
      );
    });
  });

  group('ISpectHttpInterceptor', () {
    test(
        'error payload preserved when printResponseData=false, printErrorData=true',
        () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printResponseData: false,
          enableRedaction: false,
        ),
      );

      final request = http.Request('GET', Uri.parse('https://api.example.com'));
      final response =
          http.Response('{"error":"Invalid token"}', 401, request: request);

      final future = inspector.stream
          .where((e) => e is HttpErrorLog)
          .cast<HttpErrorLog>()
          .first;

      await interceptor.interceptResponse(response: response);

      final log = await future;
      expect(log.body, isNotNull);
      expect(log.body, contains('error'));
      expect(
        log.textMessage.contains('Invalid token'),
        isTrue,
        reason: 'Error text should include parsed server error payload',
      );
    });
    test('logs parsed response body for success responses', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: false,
          printResponseMessage: false,
          enableRedaction: false,
        ),
      );

      final request = http.Request('GET', Uri.parse('https://example.com'));
      final response = http.Response(
        '{"foo": 123}',
        200,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpResponseLog)
          .cast<HttpResponseLog>()
          .first;

      await interceptor.interceptResponse(response: response);

      final log = await future;
      expect(
        log.responseBody,
        isA<Map<String, dynamic>>(),
        reason: 'Response body should be decoded to Map',
      );
      expect(
        log.textMessage.contains('foo'),
        isTrue,
        reason: 'Pretty-printed response body should be in text output',
      );
    });

    test('error logs preserve array bodies under data key', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          enableRedaction: false,
        ),
      );

      final request =
          http.Request('POST', Uri.parse('https://api.example.com/login'));
      final response = http.Response(
        '[{"field":"email","message":"Invalid"},{"field":"password","message":"Too short"}]',
        422,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpErrorLog)
          .cast<HttpErrorLog>()
          .first;

      await interceptor.interceptResponse(response: response);

      final log = await future;
      expect(log.body, isNotNull);
      expect(log.body, contains('data'));
      final data = log.body!['data'];
      expect(data, isA<List<dynamic>>());
      expect(
        log.textMessage.contains('email'),
        isTrue,
        reason: 'Array error content should appear in formatted text',
      );
    });

    test('multipart request fields/files are redacted when enabled', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printResponseData: false,
        ),
      );

      final request =
          http.MultipartRequest('POST', Uri.parse('https://upload.example.com'))
            ..fields['password'] = 'super-secret'
            ..fields['token'] = 'abc123'
            ..files.add(
              http.MultipartFile.fromString(
                'file',
                'file-content',
                filename: 'secret.txt',
              ),
            );
      final baseResponse = http.StreamedResponse(
        const Stream<List<int>>.empty(),
        200,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpResponseLog)
          .cast<HttpResponseLog>()
          .first;

      await interceptor.interceptResponse(response: baseResponse);
      final log = await future;
      final body = log.requestBody;
      expect(body, isNotNull);
      final fields = body!['fields'] as Map<String, Object?>;
      expect(
        fields.values.any((v) => v == 'super-secret' || v == 'abc123'),
        isFalse,
        reason: 'Sensitive field values must be redacted',
      );
      final files = (body['files'] as List).cast<Map<String, Object?>>();
      final filenames = files.map((m) => m['filename']?.toString()).join(',');
      expect(
        filenames.contains('secret.txt'),
        isFalse,
        reason: 'Filenames should be redacted when redaction enabled',
      );
    });

    test('omits body-bytes when redaction enabled', () async {
      final redactor = RedactionService();

      final request = http.Request('GET', Uri.parse('https://example.com'));
      final response = http.Response('binary-response', 200, request: request);

      final data = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = data.toJson(redactor: redactor);
      expect(
        json.containsKey('body-bytes'),
        isFalse,
        reason: 'body-bytes must be omitted when redaction is enabled',
      );
    });

    test('additionalData omits response body when printResponseData=false',
        () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printResponseData: false,
          enableRedaction: false,
        ),
      );

      final request = http.Request('GET', Uri.parse('https://example.com'));
      final response = http.Response(
        '{"foo": 123}',
        200,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpResponseLog)
          .cast<HttpResponseLog>()
          .first;

      await interceptor.interceptResponse(response: response);
      final log = await future;
      final additional = log.additionalData;
      expect(additional, isNotNull);
      expect(
        additional!.containsKey('body'),
        isFalse,
        reason: 'Response body must be omitted from additionalData',
      );
    });

    test('additionalData includes multipart only when printRequestData=true',
        () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: false,
          enableRedaction: false,
        ),
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://upload.example.com'),
      )..fields['a'] = '1';
      final baseResponse = http.StreamedResponse(
        const Stream<List<int>>.empty(),
        200,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpResponseLog)
          .cast<HttpResponseLog>()
          .first;

      await interceptor.interceptResponse(response: baseResponse);
      final log = await future;
      final additional = log.additionalData;
      expect(additional, isNotNull);
      expect(
        additional!.containsKey('multipart-request'),
        isFalse,
        reason: 'Multipart payload must be omitted when printRequestData=false',
      );
    });
  });

  group('JSON Serialization', () {
    test('HttpRequestData.toJson produces JSON-encodable data', () {
      final request = http.Request('GET', Uri.parse('https://example.com/test'))
        ..headers.addAll({'Authorization': 'Bearer token123'});

      final requestData = HttpRequestData(request);
      final jsonData = requestData.toJson();

      // Verify URL is stored as string, not Uri object
      expect(jsonData['url'], isA<String>());
      expect(jsonData['url'], equals('https://example.com/test'));

      // Verify the data can be JSON encoded without errors
      expect(() => jsonEncode(jsonData), returnsNormally);
    });

    test('HttpResponseData.toJson produces JSON-encodable data', () {
      final request =
          http.Request('GET', Uri.parse('https://example.com/test'));
      final response = http.Response(
        '{"success": true}',
        200,
        headers: {'Content-Type': 'application/json'},
        request: request,
      );

      final requestData = HttpRequestData(request);
      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: requestData,
        multipartRequest: null,
      );

      final jsonData = responseData.toJson();

      // Verify URL is stored as string, not Uri object
      expect(jsonData['url'], isA<String>());
      expect(jsonData['url'], equals('https://example.com/test'));

      // Verify the data can be JSON encoded without errors
      expect(() => jsonEncode(jsonData), returnsNormally);
    });

    test('JSON serialization works with null request/response', () {
      // Test with null request
      final requestData = HttpRequestData(null);
      final jsonData = requestData.toJson();

      expect(jsonData['url'], isNull);
      expect(() => jsonEncode(jsonData), returnsNormally);

      // Test with null response but valid request
      final request =
          http.Request('GET', Uri.parse('https://example.com/test'));
      final nullResponseData = HttpResponseData(
        response: null,
        baseResponse: http.Response('', 404, request: request),
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final nullJsonData = nullResponseData.toJson();
      expect(nullJsonData['url'], isA<String>());
      expect(() => jsonEncode(nullJsonData), returnsNormally);
    });

    test('HttpResponseLog can be JSON encoded without Uri serialization errors',
        () {
      final request =
          http.Request('POST', Uri.parse('https://api.example.com/users'))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer token123',
            });

      final response = http.Response(
        '{"id": 123, "created": true}',
        201,
        headers: {'Content-Type': 'application/json'},
        request: request,
      );

      final requestData = HttpRequestData(request);
      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: requestData,
        multipartRequest: null,
      );

      final log = HttpResponseLog(
        'https://api.example.com/users',
        method: 'POST',
        url: 'https://api.example.com/users',
        path: '/users',
        statusCode: 201,
        statusMessage: 'Created',
        requestHeaders: request.headers,
        headers: response.headers,
        requestBody: {'name': 'John Doe'},
        responseBody: {'id': 123, 'created': true},
        settings: const ISpectHttpInterceptorSettings(),
        responseData: responseData,
      );

      // This should not throw JsonUnsupportedObjectError
      expect(() => jsonEncode(log.toJson()), returnsNormally);

      final jsonResult = log.toJson();
      expect(jsonResult, isNotNull);
      // The additionalData should contain the response data with URL as string
      final additionalData = jsonResult['additionalData'];
      if (additionalData != null && additionalData is Map<String, dynamic>) {
        expect(additionalData['url'], isA<String>());
      }
    });
  });

  group('Redaction in JSON Export', () {
    test(
        'HttpResponseData.toJson redacts JSON body content when redaction enabled',
        () {
      final redactor = RedactionService();
      final request =
          http.Request('POST', Uri.parse('https://api.example.com/users'))
            ..headers.addAll({'Content-Type': 'application/json'});

      // Create response with sensitive data
      final response = http.Response(
        '{"userId": 123, "email": "user@example.com", "password": "secret123", "token": "abc123"}',
        200,
        headers: {'Content-Type': 'application/json'},
        request: request,
      );

      final requestData = HttpRequestData(request);
      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: requestData,
        multipartRequest: null,
      );

      // Test without redaction - should contain sensitive data
      final unredactedJson = responseData.toJson();
      expect(unredactedJson['body'], contains('secret123'));
      expect(unredactedJson['body'], contains('abc123'));

      // Test with redaction - should not contain sensitive data
      final redactedJson = responseData.toJson(
        redactor: redactor,
      );

      // Parse the redacted JSON to verify content
      final parsedBody = jsonDecode(redactedJson['body'] as String);
      expect(parsedBody, isA<Map<String, dynamic>>());

      // Sensitive data should be redacted (replaced with placeholders)
      expect(parsedBody['password'], isNot(equals('secret123')));
      expect(parsedBody['token'], isNot(equals('abc123')));

      // Non-sensitive data should remain
      expect(parsedBody['userId'], equals(123));
    });

    test('JSON export with redaction works end-to-end', () {
      final redactor = RedactionService();
      final request =
          http.Request('POST', Uri.parse('https://api.example.com/users'))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer secret-token-456',
            });

      final response = http.Response(
        '{"data": {"user": {"id": 123, "email": "test@example.com", "password": "secret123"}}, "token": "session-789"}',
        200,
        headers: {'Content-Type': 'application/json'},
        request: request,
      );

      final requestData = HttpRequestData(request);
      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: requestData,
        multipartRequest: null,
      );

      final log = HttpResponseLog(
        'https://api.example.com/users',
        method: 'POST',
        url: 'https://api.example.com/users',
        path: '/users',
        statusCode: 200,
        statusMessage: 'OK',
        requestHeaders: request.headers,
        headers: response.headers,
        requestBody: {'name': 'John Doe'},
        responseBody: {
          'data': {
            'user': {
              'id': 123,
              'email': 'test@example.com',
              'password': 'secret123',
            },
          },
          'token': 'session-789',
        },
        settings: const ISpectHttpInterceptorSettings(),
        responseData: responseData,
        redactor: redactor,
      );

      // Test that JSON export works without throwing
      expect(() => jsonEncode(log.toJson()), returnsNormally);

      final exportedJson = log.toJson();
      expect(exportedJson, isNotNull);

      // Verify that additionalData contains redacted content
      final additionalData = exportedJson['additionalData'];
      if (additionalData != null && additionalData is Map<String, dynamic>) {
        final body = additionalData['body'];
        if (body != null && body is String) {
          // Parse the exported body to verify it's valid JSON
          final parsedBody = jsonDecode(body);
          expect(parsedBody, isA<Map<String, dynamic>>());

          // The structure should be preserved but sensitive data redacted
          expect(parsedBody['data'], isA<Map<String, dynamic>>());
          expect(parsedBody['data']['user'], isA<Map<String, dynamic>>());
        }
      }
    });
  });
}
