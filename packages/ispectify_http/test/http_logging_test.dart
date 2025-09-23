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

  group('Multipart Request Logging', () {
    test('multipart request form data is logged when printRequestData=true',
        () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          enableRedaction: false,
        ),
      );

      final request =
          http.MultipartRequest('POST', Uri.parse('https://upload.example.com'))
            ..fields['username'] = 'john_doe'
            ..fields['email'] = 'john@example.com'
            ..files.add(
              http.MultipartFile.fromString(
                'avatar',
                'fake-image-data',
                filename: 'profile.jpg',
              ),
            );

      final future = inspector.stream
          .where((e) => e is HttpRequestLog)
          .cast<HttpRequestLog>()
          .first;

      await interceptor.interceptRequest(request: request);
      final log = await future;

      expect(log.body, isNotNull);
      expect(log.body, isA<Map<String, dynamic>>());

      final body = log.body! as Map<String, dynamic>;
      expect(body.containsKey('fields'), isTrue);
      expect(body.containsKey('files'), isTrue);

      final fields = body['fields'] as Map<String, dynamic>;
      expect(fields['username'], equals('john_doe'));
      expect(fields['email'], equals('john@example.com'));

      final files = body['files'] as List<dynamic>;
      expect(files.length, equals(1));
      expect(files[0]['filename'], equals('profile.jpg'));
      expect(files[0]['field'], equals('avatar'));
    });

    test('multipart request data is redacted when enableRedaction=true',
        () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
      );

      final request =
          http.MultipartRequest('POST', Uri.parse('https://upload.example.com'))
            ..fields['username'] = 'john_doe'
            ..fields['password'] = 'secret123'
            ..fields['token'] = 'sensitive-token'
            ..files.add(
              http.MultipartFile.fromString(
                'document',
                'confidential-data',
                filename: 'secret.pdf',
              ),
            );

      final future = inspector.stream
          .where((e) => e is HttpRequestLog)
          .cast<HttpRequestLog>()
          .first;

      await interceptor.interceptRequest(request: request);
      final log = await future;

      expect(log.body, isNotNull);
      final body = log.body! as Map<String, dynamic>;

      final fields = body['fields'] as Map<String, dynamic>;
      // Non-sensitive field should remain
      expect(fields['username'], equals('john_doe'));
      // Sensitive fields should be redacted
      expect(fields['password'], isNot(equals('secret123')));
      expect(fields['token'], isNot(equals('sensitive-token')));

      final files = body['files'] as List<dynamic>;
      expect(files.length, equals(1));
      // Filename should be redacted
      expect(files[0]['filename'], isNot(equals('secret.pdf')));
    });

    test('multipart request data is not logged when printRequestData=false',
        () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: false,
          enableRedaction: false,
        ),
      );

      final request =
          http.MultipartRequest('POST', Uri.parse('https://upload.example.com'))
            ..fields['username'] = 'john_doe'
            ..files.add(
              http.MultipartFile.fromString(
                'avatar',
                'fake-image-data',
                filename: 'profile.jpg',
              ),
            );

      final future = inspector.stream
          .where((e) => e is HttpRequestLog)
          .cast<HttpRequestLog>()
          .first;

      await interceptor.interceptRequest(request: request);
      final log = await future;

      expect(log.body, isNull);
    });
  });

  group('Response and Error Filtering', () {
    test('responseFilter does not suppress error logging', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          // Configure responseFilter to skip 2xx responses
          responseFilter: _skip2xxResponses,
          // Configure errorFilter to allow all errors
          errorFilter: _allowAllErrors,
        ),
      );

      // Test 2xx response - should be filtered out
      final request = http.Request('GET', Uri.parse('https://example.com/api'));
      final successResponse = http.Response(
        '{"success": true}',
        200,
        request: request,
      );

      HttpResponseLog? successLog;
      final successSubscription = inspector.stream
          .where((e) => e is HttpResponseLog)
          .cast<HttpResponseLog>()
          .listen((log) => successLog = log);

      await interceptor.interceptResponse(response: successResponse);
      await Future<void>.delayed(
          const Duration(milliseconds: 10)); // Allow async processing

      // Should be null because 2xx response was filtered out
      expect(successLog, isNull);
      await successSubscription.cancel();

      // Test 4xx error response - should NOT be filtered out despite responseFilter
      final errorRequest =
          http.Request('GET', Uri.parse('https://example.com/api'));
      final errorResponse = http.Response(
        '{"error": "Not found"}',
        404,
        request: errorRequest,
      );

      final errorFuture = inspector.stream
          .where((e) => e is HttpErrorLog)
          .cast<HttpErrorLog>()
          .first;

      await interceptor.interceptResponse(response: errorResponse);
      final errorLog = await errorFuture;

      // Should be logged because errorFilter allows it
      expect(errorLog, isNotNull);
      expect(errorLog.statusCode, 404);
    });

    test('errorFilter can still suppress specific errors', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          // Allow all responses
          responseFilter: _allowAllResponses,
          // Skip 404 errors specifically
          errorFilter: _skip404Errors,
        ),
      );

      // Test 404 error - should be filtered out by errorFilter
      final notFoundRequest =
          http.Request('GET', Uri.parse('https://example.com/api'));
      final notFoundResponse = http.Response(
        '{"error": "Not found"}',
        404,
        request: notFoundRequest,
      );

      HttpErrorLog? notFoundLog;
      final notFoundSubscription = inspector.stream
          .where((e) => e is HttpErrorLog)
          .cast<HttpErrorLog>()
          .listen((log) => notFoundLog = log);

      await interceptor.interceptResponse(response: notFoundResponse);
      await Future<void>.delayed(
          const Duration(milliseconds: 10)); // Allow async processing

      // Should be null because 404 was filtered out by errorFilter
      expect(notFoundLog, isNull);
      await notFoundSubscription.cancel();

      // Test 500 error - should be logged
      final serverErrorRequest =
          http.Request('GET', Uri.parse('https://example.com/api'));
      final serverErrorResponse = http.Response(
        '{"error": "Internal server error"}',
        500,
        request: serverErrorRequest,
      );

      final serverErrorFuture = inspector.stream
          .where((e) => e is HttpErrorLog)
          .cast<HttpErrorLog>()
          .first;

      await interceptor.interceptResponse(response: serverErrorResponse);
      final serverErrorLog = await serverErrorFuture;

      // Should be logged because errorFilter allows 500 errors
      expect(serverErrorLog, isNotNull);
      expect(serverErrorLog.statusCode, 500);
    });
  });
}

// Helper filter functions for testing
bool _skip2xxResponses(http.BaseResponse response) =>
    response.statusCode < 200 || response.statusCode >= 300;
bool _allowAllErrors(http.BaseResponse response) => true;
bool _allowAllResponses(http.BaseResponse response) => true;
bool _skip404Errors(http.BaseResponse response) => response.statusCode != 404;
