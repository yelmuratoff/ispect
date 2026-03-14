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

  group('ISpectHttpInterceptor (direct construction)', () {
    test(
        'error payload preserved when printResponseData=false, printErrorData=true',
        () {
      const settings = ISpectHttpInterceptorSettings(
        printResponseData: false,
        enableRedaction: false,
      );

      final request = http.Request('GET', Uri.parse('https://api.example.com'));
      final response =
          http.Response('{"error":"Invalid token"}', 401, request: request);

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final log = HttpErrorLog(
        'https://api.example.com',
        method: 'GET',
        url: 'https://api.example.com',
        path: '/',
        statusCode: 401,
        statusMessage: 'Unauthorized',
        settings: settings,
        body: {
          'response': {'error': 'Invalid token'},
        },
        responseData: responseData,
      );

      expect(log.body, isNotNull);
      expect(log.body!['response'], contains('error'));
      expect(
        log.textMessage.contains('Invalid token'),
        isTrue,
        reason: 'Error text should include parsed server error payload',
      );
    });

    test('logs parsed response body for success responses', () {
      const settings = ISpectHttpInterceptorSettings(
        printRequestData: false,
        printResponseMessage: false,
        enableRedaction: false,
      );

      final request = http.Request('GET', Uri.parse('https://example.com'));
      final response = http.Response('{"foo": 123}', 200, request: request);

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final log = HttpResponseLog(
        'https://example.com',
        method: 'GET',
        url: 'https://example.com',
        path: '/',
        statusCode: 200,
        statusMessage: 'OK',
        settings: settings,
        responseBody: {'foo': 123},
        responseData: responseData,
      );

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

    test('error logs preserve array bodies under data key', () {
      const settings = ISpectHttpInterceptorSettings(
        enableRedaction: false,
      );

      final request =
          http.Request('POST', Uri.parse('https://api.example.com/login'));
      final response = http.Response(
        '[{"field":"email","message":"Invalid"},{"field":"password","message":"Too short"}]',
        422,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final log = HttpErrorLog(
        'https://api.example.com/login',
        method: 'POST',
        url: 'https://api.example.com/login',
        path: '/login',
        statusCode: 422,
        statusMessage: 'Unprocessable Entity',
        settings: settings,
        body: {
          'response': {
            'data': [
              {'field': 'email', 'message': 'Invalid'},
              {'field': 'password', 'message': 'Too short'},
            ],
          },
        },
        responseData: responseData,
      );

      expect(log.body, isNotNull);
      final responseMap = log.body!['response'] as Map<String, dynamic>;
      expect(responseMap['data'], isA<List<dynamic>>());
      final data = responseMap['data'] as List<dynamic>;
      expect(data, isNotEmpty);
      expect(data.first, contains('field'));
      expect(
        log.textMessage.contains('email'),
        isTrue,
        reason: 'Array error content should appear in formatted text',
      );
    });

    test('multipart request fields/files are redacted when enabled', () {
      final redactor = RedactionService();

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

      final responseData = HttpResponseData(
        response: null,
        baseResponse: http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          request: request,
        ),
        requestData: HttpRequestData(request),
        multipartRequest: request,
      );

      final json = responseData.toJson(redactor: redactor);
      final mp = json['multipart-request'] as Map<String, dynamic>;
      final fields = mp['fields'] as Map<String, dynamic>;
      expect(
        fields.values.any((v) => v == 'super-secret' || v == 'abc123'),
        isFalse,
        reason: 'Sensitive field values must be redacted',
      );
      final files = (mp['files'] as List).cast<Map<String, Object?>>();
      final filenames = files.map((m) => m['filename']?.toString()).join(',');
      expect(
        filenames.contains('secret.txt'),
        isFalse,
        reason: 'Filenames should be redacted when redaction enabled',
      );
    });

    test('omits body-bytes when redaction enabled', () {
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

      // Test without redaction - body should be decoded to a Map
      final unredactedJson = responseData.toJson();
      expect(unredactedJson['body'], isA<Map<String, dynamic>>());
      final unredactedBody = unredactedJson['body'] as Map<String, dynamic>;
      expect(unredactedBody['password'], equals('secret123'));
      expect(unredactedBody['token'], equals('abc123'));

      // Test with redaction - should not contain sensitive data
      final redactedJson = responseData.toJson(
        redactor: redactor,
      );

      // Body should be decoded to a Map with redacted values
      final redactedBody = redactedJson['body'] as Map<String, dynamic>;
      expect(redactedBody, isA<Map<String, dynamic>>());

      // Sensitive data should be redacted (replaced with placeholders)
      expect(redactedBody['password'], isNot(equals('secret123')));
      expect(redactedBody['token'], isNot(equals('abc123')));

      // Non-sensitive data should remain
      expect(redactedBody['userId'], equals(123));
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
        if (body != null && body is Map<String, dynamic>) {
          // The structure should be preserved but sensitive data redacted
          expect(body['data'], isA<Map<String, dynamic>>());
          expect(body['data']['user'], isA<Map<String, dynamic>>());
        }
      }
    });
  });

  group('Multipart Request Logging (direct construction)', () {
    test('multipart request form data structure', () {
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

      final responseData = HttpResponseData(
        response: null,
        baseResponse: http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          request: request,
        ),
        requestData: HttpRequestData(request),
        multipartRequest: request,
      );

      final json = responseData.toJson();
      final mp = json['multipart-request'] as Map<String, dynamic>;
      expect(mp, isNotNull);
      expect(mp.containsKey('fields'), isTrue);
      expect(mp.containsKey('files'), isTrue);

      final fields = mp['fields'] as Map<String, dynamic>;
      expect(fields['username'], equals('john_doe'));
      expect(fields['email'], equals('john@example.com'));

      final files = mp['files'] as List<dynamic>;
      expect(files.length, equals(1));
      expect(files[0]['filename'], equals('profile.jpg'));
      expect(files[0]['field'], equals('avatar'));
    });

    test('multipart request data is redacted when redactor provided', () {
      final redactor = RedactionService();

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

      final responseData = HttpResponseData(
        response: null,
        baseResponse: http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          request: request,
        ),
        requestData: HttpRequestData(request),
        multipartRequest: request,
      );

      final json = responseData.toJson(redactor: redactor);
      final mp = json['multipart-request'] as Map<String, dynamic>;
      final fields = mp['fields'] as Map<String, dynamic>;

      // Non-sensitive field should remain
      expect(fields['username'], equals('john_doe'));
      // Sensitive fields should be redacted
      expect(fields['password'], isNot(equals('secret123')));
      expect(fields['token'], isNot(equals('sensitive-token')));

      final files = (mp['files'] as List).cast<Map<String, Object?>>();
      expect(files.length, equals(1));
      // Filename should be redacted
      expect(files[0]['filename'], isNot(equals('secret.pdf')));
    });

    test('HttpRequestLog body is null when not provided', () {
      const settings = ISpectHttpInterceptorSettings(
        printRequestData: false,
      );

      final log = HttpRequestLog(
        'https://upload.example.com',
        method: 'POST',
        url: 'https://upload.example.com',
        path: '/',
        headers: null,
        body: null,
        settings: settings,
      );

      expect(log.body, isNull);
    });
  });

  group('Response and Error Filtering (direct construction)', () {
    test('HttpErrorLog preserves statusCode and body', () {
      const settings = ISpectHttpInterceptorSettings();

      final log = HttpErrorLog(
        'https://example.com/api',
        method: 'GET',
        url: 'https://example.com/api',
        path: '/api',
        statusCode: 404,
        statusMessage: 'Not Found',
        settings: settings,
        body: {
          'response': {'error': 'Not found'},
        },
        responseData: null,
      );

      expect(log.statusCode, 404);
      expect(log.body, isNotNull);
      expect(log.body!['response'], contains('error'));
    });

    test('error body redaction works correctly via toJson', () {
      final redactor = RedactionService();

      final request =
          http.Request('POST', Uri.parse('https://api.example.com/login'));
      final response = http.Response(
        '{"error": "Invalid credentials", "password": "secret123", "token": "abc123token"}',
        401,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = responseData.toJson(redactor: redactor);
      final body = json['body'] as Map<String, dynamic>;

      expect(body['error'], equals('Invalid credentials'));
      expect(body['password'], isNot(equals('secret123')));
      expect(body['token'], isNot(equals('abc123token')));
    });
  });

  group('HttpResponseData body parsing', () {
    test('toJson decodes JSON body to Map, not String', () {
      final request =
          http.Request('GET', Uri.parse('https://api.example.com/data'));
      final response = http.Response(
        '{"id": 1, "name": "Alice", "items": [1, 2, 3]}',
        200,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = responseData.toJson();
      final body = json['body'];

      expect(
        body,
        isA<Map<String, dynamic>>(),
        reason: 'JSON body must be decoded to Map, not kept as String',
      );
      expect((body as Map)['id'], equals(1));
      expect(body['name'], equals('Alice'));
      expect(body['items'], equals([1, 2, 3]));
    });

    test('toJson decodes JSON array body to List, not String', () {
      final request =
          http.Request('GET', Uri.parse('https://api.example.com/list'));
      final response = http.Response(
        '[{"id": 1}, {"id": 2}]',
        200,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = responseData.toJson();
      final body = json['body'];

      expect(
        body,
        isA<List<dynamic>>(),
        reason: 'JSON array body must be decoded to List, not kept as String',
      );
      expect((body as List).length, equals(2));
    });

    test('toJson keeps non-JSON body as String', () {
      final request =
          http.Request('GET', Uri.parse('https://example.com/plain'));
      final response = http.Response(
        'Hello, plain text!',
        200,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = responseData.toJson();
      expect(
        json['body'],
        isA<String>(),
        reason: 'Non-JSON body should remain as String',
      );
      expect(json['body'], equals('Hello, plain text!'));
    });

    test('toJson with redaction decodes body to Map, not String', () {
      final redactor = RedactionService();
      final request =
          http.Request('GET', Uri.parse('https://api.example.com/user'));
      final response = http.Response(
        '{"userId": 1, "email": "a@b.com", "password": "secret"}',
        200,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = responseData.toJson(redactor: redactor);
      final body = json['body'];

      expect(
        body,
        isA<Map<String, dynamic>>(),
        reason: 'Redacted JSON body must be a Map, not a JSON-encoded String',
      );
      expect((body as Map)['userId'], equals(1));
      expect(body['password'], isNot(equals('secret')));
    });

    test('metadata body is JSON-encodable after parsing', () {
      final request =
          http.Request('GET', Uri.parse('https://api.example.com/data'));
      final response = http.Response(
        '{"nested": {"deep": {"value": 42}}, "list": [1, "two", true]}',
        200,
        request: request,
      );

      final responseData = HttpResponseData(
        response: response,
        baseResponse: response,
        requestData: HttpRequestData(request),
        multipartRequest: null,
      );

      final json = responseData.toJson();
      expect(
        () => jsonEncode(json),
        returnsNormally,
        reason: 'Decoded body in metadata must remain JSON-encodable',
      );
    });
  });
}
