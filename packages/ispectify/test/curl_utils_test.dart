import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('CurlUtils', () {
    test('generateCurl returns null for null data', () {
      expect(CurlUtils.generateCurl(null), isNull);
    });

    test('generateCurl returns null for missing method', () {
      final data = {'uri': 'https://example.com'};
      expect(CurlUtils.generateCurl(data), isNull);
    });

    test('generateCurl returns null for missing uri/url', () {
      final data = {'method': 'GET'};
      expect(CurlUtils.generateCurl(data), isNull);
    });

    test('generateCurl generates basic GET request', () {
      final data = {
        'method': 'GET',
        'uri': 'https://example.com',
      };
      final curl = CurlUtils.generateCurl(data);
      expect(curl, equals('curl -X GET "https://example.com"'));
    });

    test('generateCurl generates POST request with headers and body', () {
      final data = {
        'method': 'POST',
        'url': 'https://api.example.com/endpoint',
        'headers': {
          'Authorization': 'Bearer token',
          'Content-Type': 'application/json',
        },
        'data': '{"name": "test"}',
      };
      final curl = CurlUtils.generateCurl(data);
      expect(curl, contains('curl -X POST "https://api.example.com/endpoint"'));
      expect(curl, contains('-H "Authorization: Bearer token"'));
      expect(curl, contains('-H "Content-Type: application/json"'));
      expect(curl, contains("-d '{\"name\": \"test\"}'"));
    });

    test('generateCurl handles null headers gracefully', () {
      final data = {
        'method': 'PUT',
        'uri': 'https://example.com',
        'headers': null,
        'data': 'plain text',
      };
      final curl = CurlUtils.generateCurl(data);
      expect(
        curl,
        equals('curl -X PUT "https://example.com" -d \'plain text\''),
      );
    });

    test('generateCurl prefers uri over url', () {
      final data = {
        'method': 'GET',
        'uri': 'https://uri.example.com',
        'url': 'https://url.example.com',
      };
      final curl = CurlUtils.generateCurl(data);
      expect(curl, contains('"https://uri.example.com"'));
    });
  });
}
