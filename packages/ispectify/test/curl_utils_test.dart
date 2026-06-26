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
      expect(curl, equals("curl -X 'GET' 'https://example.com'"));
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
      expect(
        curl,
        contains("curl -X 'POST' 'https://api.example.com/endpoint'"),
      );
      expect(curl, contains("-H 'Authorization: Bearer token'"));
      expect(curl, contains("-H 'Content-Type: application/json'"));
      expect(curl, contains('''-d '{"name": "test"}' '''.trim()));
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
        equals("curl -X 'PUT' 'https://example.com' -d 'plain text'"),
      );
    });

    test('generateCurl prefers uri over url', () {
      final data = {
        'method': 'GET',
        'uri': 'https://uri.example.com',
        'url': 'https://url.example.com',
      };
      final curl = CurlUtils.generateCurl(data);
      expect(curl, contains("'https://uri.example.com'"));
    });

    test('generateCurl escapes single quotes in values', () {
      final data = {
        'method': 'POST',
        'uri': 'https://example.com',
        'data': "it's a test",
      };
      final curl = CurlUtils.generateCurl(data);
      expect(curl, isNotNull);
      // Single quotes in values are escaped as '\''
      expect(curl, contains(r"it'\''s a test"));
    });

    test('generateCurl escapes shell metacharacters in headers', () {
      final data = {
        'method': 'GET',
        'uri': 'https://example.com',
        'headers': {
          'X-Custom': 'value"; rm -rf / #',
        },
      };
      final curl = CurlUtils.generateCurl(data);
      expect(curl, isNotNull);
      // Dangerous shell characters are safely wrapped in single quotes
      expect(curl!.contains('rm -rf'), isTrue);
      expect(curl.contains('" ;'), isFalse);
    });

    group('redactor', () {
      test('redacts Authorization header when redactor is provided', () {
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com/v1/me',
          'headers': {
            'Authorization': 'Bearer s3cret-token-value',
            'Content-Type': 'application/json',
          },
        };
        final curl = CurlUtils.generateCurl(data, redactor: RedactionService());
        expect(curl, isNotNull);
        expect(curl, isNot(contains('s3cret-token-value')));
        expect(curl, isNot(contains('Bearer s3cret-token-value')));
        // Non-sensitive headers survive untouched.
        expect(curl, contains("-H 'Content-Type: application/json'"));
      });

      test('redacts Cookie and X-API-Key headers', () {
        final data = {
          'method': 'GET',
          'uri': 'https://api.example.com',
          'headers': {
            'Cookie': 'session=abc123; refresh=def456',
            'X-API-Key': 'live_pk_aaaaaaaa',
          },
        };
        final curl = CurlUtils.generateCurl(data, redactor: RedactionService());
        expect(curl, isNotNull);
        expect(curl, isNot(contains('abc123')));
        expect(curl, isNot(contains('def456')));
        expect(curl, isNot(contains('live_pk_aaaaaaaa')));
      });

      test('redacts sensitive keys in JSON body', () {
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com/login',
          'headers': <String, Object?>{},
          'data': {'locale': 'en_US', 'password': 'p@ssw0rd!'},
        };
        final curl = CurlUtils.generateCurl(data, redactor: RedactionService());
        expect(curl, isNotNull);
        expect(curl, isNot(contains('p@ssw0rd!')));
        // Non-sensitive payload values pass through unchanged.
        expect(curl, contains('en_US'));
      });

      test('redacts sensitive query parameters in the URL', () {
        final data = {
          'method': 'GET',
          'uri': 'https://api.example.com/v1/me?token=secret123&page=2',
        };
        final curl = CurlUtils.generateCurl(data, redactor: RedactionService());
        expect(curl, isNotNull);
        expect(curl, isNot(contains('secret123')));
        // Non-sensitive query parameters survive.
        expect(curl, contains('page=2'));
      });

      test('redacts userInfo credentials in the URL', () {
        final data = {
          'method': 'GET',
          'uri': 'https://alice:hunter2@api.example.com/path',
        };
        final curl = CurlUtils.generateCurl(data, redactor: RedactionService());
        expect(curl, isNotNull);
        expect(curl, isNot(contains('alice:hunter2')));
        expect(curl, isNot(contains('hunter2')));
      });

      test('passes the raw URL through when redactor is null', () {
        final data = {
          'method': 'GET',
          'uri': 'https://api.example.com/v1/me?token=secret123',
        };
        final curl = CurlUtils.generateCurl(data);
        expect(curl, contains('token=secret123'));
      });

      test('passes raw headers and body through when redactor is null', () {
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com',
          'headers': {'Authorization': 'Bearer raw-token'},
          'data': '{"password":"raw"}',
        };
        final curl = CurlUtils.generateCurl(data);
        expect(curl, contains('Bearer raw-token'));
        expect(curl, contains('"password":"raw"'));
      });

      test('preserves shell-escape after redaction', () {
        final data = {
          'method': 'POST',
          'uri': 'https://example.com',
          'headers': {
            'X-Custom': 'value"; rm -rf / #',
            'Authorization': 'Bearer secret',
          },
          'data': "it's a test",
        };
        final curl = CurlUtils.generateCurl(data, redactor: RedactionService());
        expect(curl, isNotNull);
        // Single quotes in values still escaped as '\''
        expect(curl, contains(r"it'\''s a test"));
        // Sensitive header masked, non-sensitive escaped safely
        expect(curl, isNot(contains('Bearer secret')));
        expect(curl!.contains('rm -rf'), isTrue);
        expect(curl.contains('" ;'), isFalse);
      });
    });
  });
}
