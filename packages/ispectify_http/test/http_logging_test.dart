// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

void main() {
  group('JSON Serialization', () {
    test('HttpRequestData.toJson produces JSON-encodable data', () {
      final request = http.Request('GET', Uri.parse('https://example.com/test'))
        ..headers.addAll({'Authorization': 'Bearer token123'});

      final requestData = HttpRequestData(request);
      final jsonData = requestData.toJson();

      expect(jsonData['url'], isA<String>());
      expect(jsonData['url'], equals('https://example.com/test'));
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

      expect(jsonData['url'], isA<String>());
      expect(jsonData['url'], equals('https://example.com/test'));
      expect(() => jsonEncode(jsonData), returnsNormally);
    });

    test('JSON serialization works with null request/response', () {
      final requestData = HttpRequestData(null);
      final jsonData = requestData.toJson();

      expect(jsonData['url'], isNull);
      expect(() => jsonEncode(jsonData), returnsNormally);

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
  });

  group('Redaction in JSON Export', () {
    test(
      'HttpResponseData.toJson redacts JSON body content when redaction enabled',
      () {
        final redactor = RedactionService();
        final request =
            http.Request('POST', Uri.parse('https://api.example.com/users'))
              ..headers.addAll({'Content-Type': 'application/json'});

        final response = http.Response(
          '{"userId": 123, "password": "secret123", "token": "abc123"}',
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

        final unredactedJson = responseData.toJson();
        expect(unredactedJson['body'], isA<Map<String, dynamic>>());
        final unredactedBody = unredactedJson['body'] as Map<String, dynamic>;
        expect(unredactedBody['password'], equals('secret123'));
        expect(unredactedBody['token'], equals('abc123'));

        final redactedJson = responseData.toJson(redactor: redactor);
        final redactedBody = redactedJson['body'] as Map<String, dynamic>;
        expect(redactedBody['password'], isNot(equals('secret123')));
        expect(redactedBody['token'], isNot(equals('abc123')));
        expect(redactedBody['userId'], equals(123));
      },
    );
  });

  group('Multipart Request Logging', () {
    test('multipart request form data structure', () {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://example.com/upload'),
      )
        ..fields['name'] = 'test'
        ..fields['description'] = 'A test file';

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
      final fields = mp['fields'] as Map<String, dynamic>;
      expect(fields['name'], equals('test'));
      expect(fields['description'], equals('A test file'));
    });

    test('multipart request data is redacted when redactor provided', () {
      final redactor = RedactionService();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://example.com/upload'),
      )
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

      // 'username' is now in defaultSensitiveKeys — it gets redacted
      expect(fields['username'], isNot(equals('john_doe')));
      expect(fields['password'], isNot(equals('secret123')));
      expect(fields['token'], isNot(equals('sensitive-token')));

      final files = (mp['files'] as List<dynamic>).cast<Map<String, Object?>>();
      expect(files.length, equals(1));
      expect(files[0]['filename'], isNot(equals('secret.pdf')));
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

      expect(body, isA<Map<String, dynamic>>());
      expect((body as Map<String, dynamic>)['id'], equals(1));
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

      expect(body, isA<List<dynamic>>());
      expect((body as List<dynamic>).length, equals(2));
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
      expect(json['body'], isA<String>());
      expect(json['body'], equals('Hello, plain text!'));
    });

    test('toJson with redaction decodes body to Map, not String', () {
      final redactor = RedactionService();
      final request =
          http.Request('GET', Uri.parse('https://api.example.com/data'));
      final response = http.Response(
        '{"id": 1, "token": "secret"}',
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

      expect(body, isA<Map<String, dynamic>>());
    });

    test('metadata body is JSON-encodable after parsing', () {
      final request =
          http.Request('GET', Uri.parse('https://api.example.com/data'));
      final response = http.Response(
        '{"nested": {"key": "value"}, "list": [1, 2, 3]}',
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
      expect(() => jsonEncode(json), returnsNormally);
    });
  });
}
