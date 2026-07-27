import 'dart:typed_data';

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
      expect(
        curl,
        equals("curl -X 'GET' --url 'https://example.com'"),
      );
    });

    test('generateCurl binds a dash-prefixed target to --url', () {
      final curl = CurlUtils.generateCurl({
        'method': 'GET',
        'uri': '--config',
      });

      expect(curl, equals("curl -X 'GET' --url '--config'"));
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
        contains(
          "curl -X 'POST' --url 'https://api.example.com/endpoint'",
        ),
      );
      expect(curl, contains("-H 'Authorization: Bearer [REDACTED]'"));
      expect(curl, contains("-H 'Content-Type: application/json'"));
      expect(curl, contains('''--data-raw '{"name":"test"}' '''.trim()));
    });

    test('drops a captured Content-Length when emitting a body', () {
      final curl = CurlUtils.generateCurl({
        'method': 'POST',
        'uri': 'https://api.example.com/login',
        'headers': const {
          'Content-Length': '999',
          'content-type': 'application/json',
        },
        'data': const {
          'password': 'LENGTH_CHANGING_SECRET',
          'safe': 'visible',
        },
      });

      expect(curl, isNot(contains('Content-Length')));
      expect(curl, contains("-H 'content-type: application/json'"));
      expect(curl, isNot(contains('LENGTH_CHANGING_SECRET')));
      expect(curl, contains('--data-raw'));
    });

    test('keeps Content-Length when no body is emitted', () {
      final curl = CurlUtils.generateCurl({
        'method': 'GET',
        'uri': 'https://api.example.com',
        'headers': const {'content-length': '0'},
      });

      expect(curl, contains("-H 'content-length: 0'"));
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
        equals(
          "curl -X 'PUT' --url 'https://example.com' "
          "--data-raw 'plain text'",
        ),
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

    test('generateCurl returns null for invalid required field types', () {
      expect(
        CurlUtils.generateCurl({
          'method': 'GET',
          'uri': 1,
          'url': <String>[],
        }),
        isNull,
      );
      expect(
        CurlUtils.generateCurl({
          'method': 1,
          'uri': 'https://example.com',
        }),
        isNull,
      );
    });

    test('generateCurl ignores malformed optional headers', () {
      expect(
        CurlUtils.generateCurl({
          'method': 'GET',
          'uri': 'https://example.com',
          'headers': <Object?>[],
        }),
        "curl -X 'GET' --url 'https://example.com'",
      );
    });

    test('emits normalized list-valued headers as repeated fields', () {
      final curl = CurlUtils.generateCurl({
        'method': 'GET',
        'uri': 'https://example.com',
        'headers': const {
          'X-Tag': ['first', 'second'],
        },
      });

      expect(curl, contains("-H 'X-Tag: first'"));
      expect(curl, contains("-H 'X-Tag: second'"));
    });

    test('bounds emitted values from list-valued headers', () {
      final curl = CurlUtils.generateCurl({
        'method': 'GET',
        'uri': 'https://example.com',
        'headers': {
          'X-Tag': [
            for (var index = 0; index <= 100; index++) 'value-$index',
          ],
        },
      });

      expect(
        RegExp("-H 'X-Tag:").allMatches(curl!).length,
        lessThanOrEqualTo(100),
      );
      expect(curl, isNot(contains('value-100')));
    });

    test('bounds malformed header maps by every visited entry', () {
      final headers = <Object?, Object?>{
        for (var index = 0;
            index < JsonValueNormalizer.defaultMaxCollectionItems;
            index++)
          index: 'ignored',
        'X-After-Limit': 'must-not-be-visited',
      };

      final curl = CurlUtils.generateCurl({
        'method': 'GET',
        'uri': 'https://example.com',
        'headers': headers,
      });

      expect(curl, isNot(contains('X-After-Limit')));
      expect(curl, isNot(contains('must-not-be-visited')));
    });

    test('normalizes hostile header values before interpolation', () {
      final value = _ThrowingHeaderValue();
      final curl = CurlUtils.generateCurl({
        'method': 'GET',
        'uri': 'https://example.com',
        'headers': {'X-Hostile': value},
      });

      expect(curl, contains(JsonValueNormalizer.unprintableValue));
      expect(value.calls, 0);
    });

    test('bounds the command before escaping oversized values', () {
      final huge = _asciiString(4 * 1024 * 1024, 39);
      final curl = CurlUtils.generateCurl(
        {
          'method': 'POST',
          'uri': huge,
          'headers': {'X-Large': huge},
          'data': huge,
        },
        enableRedaction: false,
      );

      expect(curl, isNotNull);
      expect(
        LogExportOutput.utf8Length(curl!),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('bounds multi-megabyte binary bodies before replay rendering', () {
      final curl = CurlUtils.generateCurl(
        {
          'method': 'POST',
          'uri': 'https://example.com',
          'data': Uint8List(4 * 1024 * 1024),
        },
        enableRedaction: false,
      );

      expect(curl, isNotNull);
      expect(
        LogExportOutput.utf8Length(curl!),
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
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
      test('redacts caller-controlled method text by default', () {
        const secret = 'CURL-METHOD-SECRET';

        final curl = CurlUtils.generateCurl({
          'method': 'GET token=$secret',
          'uri': 'https://api.example.com',
        });

        expect(curl, isNot(contains(secret)));
      });

      test('uses an explicit service for caller-controlled method text', () {
        const secret = 'CURL-EXPLICIT-METHOD';

        final curl = CurlUtils.generateCurl(
          {
            'method': 'TRACE tenantSecret=$secret',
            'uri': 'https://api.example.com',
          },
          redactor: RedactionService(
            sensitiveKeys: const {'tenantSecret'},
            placeholder: '<EXPLICIT_METHOD>',
          ),
        );

        expect(curl, contains('<EXPLICIT_METHOD>'));
        expect(curl, isNot(contains(secret)));
      });

      test('method redaction honors an explicit opt-out', () {
        const secret = 'CURL-RAW-METHOD';

        final curl = CurlUtils.generateCurl(
          {
            'method': 'GET token=$secret',
            'uri': 'https://api.example.com',
          },
          enableRedaction: false,
        );

        expect(curl, contains(secret));
      });

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

      test('scrubs caller data from header names and arbitrary values', () {
        const rawName = 'sk-CURLHEADERNAMESECRET123456';
        const valueSecret = 'CURL-ARBITRARY-HEADER-VALUE';
        const cookieNameSecret = 'sk-CURL-COOKIE-NAME-SECRET-123456';

        final curl = CurlUtils.generateCurl({
          'method': 'GET',
          'uri': 'https://api.example.com',
          'headers': const <String, Object?>{
            rawName: 'password=$valueSecret',
            'Cookie': '$cookieNameSecret=value',
          },
        });

        expect(curl, isNot(contains(rawName)));
        expect(curl, isNot(contains(valueSecret)));
        expect(curl, isNot(contains(cookieNameSecret)));
        expect(curl, contains(defaultPlaceholder));
      });

      test('uses an explicit service to scrub PII from a header name', () {
        const rawName = 'email=curl.person@example.test';
        const valueSecret = 'CURL-EXPLICIT-HEADER-VALUE';

        final curl = CurlUtils.generateCurl(
          {
            'method': 'GET',
            'uri': 'https://api.example.com',
            'headers': const <String, Object?>{
              rawName: 'tenantSecret=$valueSecret',
            },
          },
          redactor: RedactionService(
            sensitiveKeys: const {'email', 'tenantSecret'},
            sensitiveKeyPatterns: const <RegExp>[],
            placeholder: '<CURL_HEADER>',
          ),
        );

        expect(curl, contains('<CURL_HEADER>'));
        expect(curl, isNot(contains('curl.person@example.test')));
        expect(curl, isNot(contains(valueSecret)));
      });

      test('fully masks credentials for future authorization schemes', () {
        const authorizationSecret =
            'AUTHORIZATION_PREFIX_secret_AUTHORIZATION_SUFFIX';
        const proxySecret = 'PROXY_PREFIX_secret_PROXY_SUFFIX';
        final curl = CurlUtils.generateCurl({
          'method': 'GET',
          'uri': 'https://api.example.com',
          'headers': const {
            'Authorization': 'DPoP $authorizationSecret',
            'Proxy-Authorization': 'GNAP $proxySecret',
          },
        });

        expect(
          curl,
          contains("-H 'Authorization: DPoP [REDACTED]'"),
        );
        expect(
          curl,
          contains("-H 'Proxy-Authorization: GNAP [REDACTED]'"),
        );
        expect(curl, isNot(contains('AUTHORIZATION_PREFIX')));
        expect(curl, isNot(contains('AUTHORIZATION_SUFFIX')));
        expect(curl, isNot(contains('PROXY_PREFIX')));
        expect(curl, isNot(contains('PROXY_SUFFIX')));
      });

      test('redacts typed binary values in custom headers', () {
        final curl = CurlUtils.generateCurl({
          'method': 'GET',
          'uri': 'https://api.example.com',
          'headers': {
            'X-Binary': Uint8List.fromList(List<int>.filled(64, 255)),
          },
        });

        expect(curl, contains("-H 'X-Binary: ["));
        expect(curl, isNot(contains('255')));
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

      test('redacts sensitive keys in a JSON-encoded string body', () {
        const secret = 'CURL-JSON-STRING-SECRET';
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com/login',
          'data': '{"locale":"en_US","password":"$secret"}',
        };

        final curl = CurlUtils.generateCurl(
          data,
          redactor: RedactionService(),
        );

        expect(curl, isNotNull);
        expect(curl, contains('en_US'));
        expect(curl, isNot(contains(secret)));
      });

      test('scrubs malformed JSON with configured sensitive keys', () {
        const secret = 'CURL-MALFORMED-CUSTOM-SECRET';
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com/login',
          'data': '{"tenantSecret":"$secret",}',
        };

        final curl = CurlUtils.generateCurl(
          data,
          redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
        );

        expect(curl, isNotNull);
        expect(curl, isNot(contains(secret)));
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

      test('fails closed for encoded and malformed URL keys', () {
        for (final uri in const [
          'https://api.example.com?%2574oken=DOUBLE_ENCODED_SECRET',
          'https://api.example.com?%ZZ=MALFORMED_QUERY_SECRET',
          'https://api.example.com#%ZZ=MALFORMED_FRAGMENT_SECRET',
        ]) {
          final curl = CurlUtils.generateCurl({
            'method': 'GET',
            'uri': uri,
          });

          expect(curl, isNot(contains('ENCODED_SECRET')));
          expect(curl, isNot(contains('QUERY_SECRET')));
          expect(curl, isNot(contains('FRAGMENT_SECRET')));
          expect(curl, contains('REDACTED'));
        }
      });

      test('preserves repeated and bare safe query parameters', () {
        final curl = CurlUtils.generateCurl({
          'method': 'GET',
          'uri': 'https://api.example.com/items'
              '?tag=one&tag=two&flag&token=secret',
        });

        expect(curl, contains('tag=one&tag=two&flag&token='));
        expect(curl, isNot(contains('secret')));
        expect(curl, isNot(contains('flag=')));
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

      test('requires an explicit opt-out to retain a raw URL', () {
        final data = {
          'method': 'GET',
          'uri': 'https://api.example.com/v1/me?token=secret123',
        };
        final curl = CurlUtils.generateCurl(data, enableRedaction: false);
        expect(curl, contains('token=secret123'));
      });

      test('requires an explicit opt-out to retain raw headers and body', () {
        const rawName = 'email=raw.curl.person@example.test';
        const rawHeaderValue = 'password=RAW-CURL-HEADER-VALUE';
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com',
          'headers': {
            'Authorization': 'Bearer raw-token',
            rawName: rawHeaderValue,
          },
          'data': '{"password":"raw"}',
        };
        final curl = CurlUtils.generateCurl(data, enableRedaction: false);
        expect(curl, contains('Bearer raw-token'));
        expect(curl, contains(rawName));
        expect(curl, contains(rawHeaderValue));
        expect(curl, contains('"password":"raw"'));
      });

      test('redacts URL, headers, and body when no redactor is supplied', () {
        final data = {
          'method': 'POST',
          'uri': 'https://api.example.com?token=url-secret',
          'headers': {'Authorization': 'Bearer header-secret'},
          'data': '{"password":"body-secret"}',
        };

        final curl = CurlUtils.generateCurl(data);

        expect(curl, isNot(contains('url-secret')));
        expect(curl, isNot(contains('header-secret')));
        expect(curl, isNot(contains('body-secret')));
      });

      test('uses the configured global service when no redactor is supplied',
          () {
        addTearDown(ISpectRedaction.reset);
        ISpectRedaction.configure(
          service: RedactionService(
            sensitiveKeys: const {'business_marker'},
            placeholder: '<GLOBAL_POLICY>',
          ),
        );

        final curl = CurlUtils.generateCurl({
          'method': 'POST business_marker=global-method-secret',
          'uri': 'https://api.example.com',
          'headers': const <String, Object?>{
            'business_marker=global-header-name-secret':
                'business_marker=global-header-value-secret',
          },
          'data': const {'business_marker': 'curl-secret'},
        });

        expect(curl, isNot(contains('curl-secret')));
        expect(curl, isNot(contains('global-method-secret')));
        expect(curl, isNot(contains('global-header-name-secret')));
        expect(curl, isNot(contains('global-header-value-secret')));
        expect(curl, contains('<GLOBAL_POLICY>'));
      });

      test('uses data-raw so an at-prefixed body cannot read a local file', () {
        final curl = CurlUtils.generateCurl({
          'method': 'POST',
          'uri': 'https://api.example.com',
          'data': '@/etc/passwd',
        });

        expect(curl, contains("--data-raw '@/etc/passwd'"));
        expect(curl, isNot(contains(" -d '@/etc/passwd'")));
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

final class _ThrowingHeaderValue {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('must not escape');
  }
}

String _asciiString(int length, int codeUnit) =>
    String.fromCharCodes(Uint8List(length)..fillRange(0, length, codeUnit));
