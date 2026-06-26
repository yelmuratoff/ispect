import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('RedactionService', () {
    test('redacts sensitive headers by default', () {
      final service = RedactionService();
      final headers = service.redactHeaders({
        'Authorization': 'Bearer secret-token',
        'X-Custom': 'visible',
      });

      expect(headers['Authorization'], contains('[REDACTED]'));
      expect(headers['X-Custom'], 'visible');
    });

    test('respects per-call ignored keys', () {
      final service = RedactionService();
      final headers = service.redactHeaders(
        {'Authorization': 'visible'},
        ignoredKeys: {'Authorization'},
      );

      expect(headers['Authorization'], 'visible');
    });

    test('honours ignored values', () {
      final service = RedactionService(ignoredValues: {'SAFE'});

      final map = service.redact({'token': 'SAFE'}) as Map<String, Object?>?;
      expect(map, isNotNull);
      expect(map!['token'], 'SAFE');
    });

    test('fully masks configured keys that are also sensitive', () {
      final service = RedactionService(fullyMaskedKeys: {'apiKey'});
      final map =
          service.redact({'apiKey': '123456789'}) as Map<String, Object?>?;
      expect(map, isNotNull);
      expect(map!['apiKey'], '[REDACTED]');
    });

    test('fully masks configured keys even when not sensitive', () {
      final service = RedactionService(fullyMaskedKeys: {'filename'});
      final map =
          service.redact({'filename': 'report.pdf'}) as Map<String, Object?>?;
      expect(map, isNotNull);
      expect(map!['filename'], '[REDACTED]');
    });

    test('redacts binary payloads when enabled', () {
      final service = RedactionService();
      final data = Uint8List.fromList(List<int>.generate(16, (i) => i));

      final map = service.redact({'data': data}) as Map<String, Object?>?;
      expect(map, isNotNull);
      final redacted = map!['data'] as List?;
      expect(redacted, isNotNull);
      expect(identical(redacted, data), isFalse);
      expect(redacted!.length, data.length);
    });

    test('deprecated kDefaultSensitiveKeys alias still works', () {
      // ignore: deprecated_member_use_from_same_package
      expect(kDefaultSensitiveKeys, equals(defaultSensitiveKeys));
    });

    group('camelCase and whitespace key matching', () {
      test('redacts camelCase credential keys', () {
        final service = RedactionService();
        final map = service.redact({
          'accessToken': 'aaa-access-secret-bbb',
          'refreshToken': 'ccc-refresh-secret-ddd',
          'idToken': 'eee-id-secret-fff',
          'displayName': 'Alice',
        })! as Map<String, Object?>;

        expect(map['accessToken'], isNot(contains('access-secret')));
        expect(map['refreshToken'], isNot(contains('refresh-secret')));
        expect(map['idToken'], isNot(contains('id-secret')));
        expect(map['displayName'], 'Alice');
      });

      test('redacts camelCase password keys', () {
        final service = RedactionService();
        final map = service.redact({
          'confirmPassword': 'pw-confirm-secret',
          'newPassword': 'pw-new-secret',
        })! as Map<String, Object?>;

        expect(map['confirmPassword'], isNot(contains('confirm-secret')));
        expect(map['newPassword'], isNot(contains('new-secret')));
      });

      test('redacts PascalCase and other camelCase sensitive keys', () {
        final service = RedactionService();
        final map = service.redact({
          'AccessToken': 'pascal-secret-value',
          'sessionId': 'session-secret-value',
          'cardNumber': '4111-1111-1111-1111',
        })! as Map<String, Object?>;

        expect(map['AccessToken'], isNot(contains('pascal-secret-value')));
        expect(map['sessionId'], isNot(contains('session-secret-value')));
        expect(map['cardNumber'], isNot(contains('4111-1111-1111-1111')));
      });

      test('redacts keys with surrounding whitespace', () {
        final service = RedactionService();
        final headers = service.redactHeaders({
          'authorization ': 'Bearer ws-secret-token',
        });

        expect(headers['authorization '], isNot(contains('ws-secret-token')));
        expect(headers['authorization '], contains('[REDACTED]'));
      });

      test('leaves non-sensitive camelCase keys untouched', () {
        final service = RedactionService();
        final map = service.redact({
          'firstName': 'Alice',
          'createdAt': '2026-01-01',
          'itemKeyboard': 'visible',
        })! as Map<String, Object?>;

        expect(map['firstName'], 'Alice');
        expect(map['createdAt'], '2026-01-01');
        expect(map['itemKeyboard'], 'visible');
      });

      test('per-call ignored camelCase key is not redacted', () {
        final service = RedactionService();
        final map = service.redact(
          {'accessToken': 'visible-value'},
          ignoredKeys: {'accessToken'},
        )! as Map<String, Object?>;

        expect(map['accessToken'], 'visible-value');
      });
    });

    group('full masking of high-sensitivity keys', () {
      test('fully masks credentials without revealing edge characters', () {
        final service = RedactionService();
        final map = service.redact({
          'password': 'abcdefghijklmnop',
          'access_token': 'eyJhbGciOi.payloadpayload.signaturesig',
          'secret': 'topsecretvalue123',
        })! as Map<String, Object?>;

        expect(map['password'], '[REDACTED]');
        expect(map['access_token'], '[REDACTED]');
        expect(map['secret'], '[REDACTED]');
      });

      test('fully masks financial and government identifiers', () {
        final service = RedactionService();
        final map = service.redact({
          'ssn': '123-45-6789',
          'iban': 'DE89370400440532013000',
          'cardNumber': '4111111111111111',
          'cvv': '123',
        })! as Map<String, Object?>;

        expect(map['ssn'], '[REDACTED]');
        expect(map['iban'], '[REDACTED]');
        expect(map['cardNumber'], '[REDACTED]');
        expect(map['cvv'], '[REDACTED]');
      });

      test('keeps structure-aware masking for authorization', () {
        final service = RedactionService();
        final headers = service.redactHeaders({
          'authorization': 'Bearer aaaaaaaaaaaaaaaaaaaa',
        });

        expect(headers['authorization'], startsWith('Bearer '));
        expect(
          headers['authorization'],
          isNot(contains('aaaaaaaaaaaaaaaaaaaa')),
        );
        expect(headers['authorization'], isNot('[REDACTED]'));
      });
    });

    group('additional sensitive key variants', () {
      test('recognizes password abbreviations and fragments', () {
        final service = RedactionService();
        final map = service.redact({
          'pwd': 'shorty1',
          'passwd': 'shorty2',
          'user_pwd': 'shorty3',
        })! as Map<String, Object?>;

        expect(map['pwd'], '[REDACTED]');
        expect(map['passwd'], '[REDACTED]');
        expect(map['user_pwd'], isNot('shorty3'));
      });

      test('recognizes signature, hmac, pan, dob, and xsrf keys', () {
        final service = RedactionService();
        final map = service.redact({
          'signature': 'sig-aaaaaaaaaaaa',
          'hmac': 'hmac-aaaaaaaaaaaa',
          'pan': '4111111111111111',
          'dateOfBirth': '1990-01-01',
          'xsrf': 'xsrf-aaaaaaaaaaaa',
        })! as Map<String, Object?>;

        expect(map['signature'], '[REDACTED]');
        expect(map['hmac'], '[REDACTED]');
        expect(map['pan'], '[REDACTED]');
        expect(map['dateOfBirth'], isNot('1990-01-01'));
        expect(map['xsrf'], '[REDACTED]');
      });
    });

    group('redactByKeys', () {
      test('matches a mixed-case Set against lowercase data keys', () {
        final result = RedactionService.redactByKeys(
          {'authorization': 'Bearer secret', 'safe': 'visible'},
          {'Authorization'},
        )! as Map<String, Object?>;

        expect(result['authorization'], '***');
        expect(result['safe'], 'visible');
      });

      test('matches lowercase keys against mixed-case data keys', () {
        final result = RedactionService.redactByKeys(
          {'Authorization': 'Bearer secret'},
          {'authorization'},
        )! as Map<String, Object?>;

        expect(result['Authorization'], '***');
      });
    });

    group('redactUrl', () {
      test('returns original URL when nothing to redact', () {
        final service = RedactionService();
        const url = 'https://example.com/api/users';
        expect(service.redactUrl(url), url);
      });

      test('redacts query parameter values', () {
        final service = RedactionService();
        final result =
            service.redactUrl('https://example.com/api?api_key=secret123');
        expect(result, contains('api_key='));
        expect(result, isNot(contains('secret123')));
      });

      test('redacts userInfo credentials', () {
        final service = RedactionService();
        final result = service.redactUrl('https://user:pass@example.com/path');
        expect(result, contains('REDACTED'));
        expect(result, isNot(contains('user:pass')));
      });

      test('returns unparseable URL unchanged', () {
        final service = RedactionService();
        const bad = ':::not-a-url';
        expect(service.redactUrl(bad), bad);
      });
    });

    group('redactUrlsInText', () {
      test('redacts URLs embedded in error messages', () {
        final service = RedactionService();
        final result = service.redactUrlsInText(
          'Connection failed to https://user:pass@api.io/v1?token=abc',
        );
        expect(result, contains('REDACTED'));
        expect(result, isNot(contains('user:pass')));
        expect(result, startsWith('Connection failed to '));
      });

      test('leaves text without URLs unchanged', () {
        final service = RedactionService();
        const plain = 'No URLs here at all';
        expect(service.redactUrlsInText(plain), plain);
      });
    });

    group('redactWithStats', () {
      test('returns stats with key-based redaction count', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'authorization': 'Bearer secret-token',
          'username': 'john',
          'safe_field': 'visible',
        });

        expect(result.data, isA<Map<String, Object?>>());
        expect(result.stats.keyBased, 2);
        expect(result.stats.patternBased, 0);
        expect(result.stats.total, 2);
        expect(result.stats.hasRedactions, isTrue);
      });

      test('returns stats with pattern-based redaction count', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'ghp_abc123def456ghi789',
        });

        expect(result.stats.patternBased, greaterThan(0));
        expect(result.stats.hasRedactions, isTrue);
      });

      test('returns zero stats when nothing redacted', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'name': 'hello',
          'count': 42,
        });

        expect(result.stats.total, 0);
        expect(result.stats.hasRedactions, isFalse);
      });
    });

    group('redactHeadersWithStats', () {
      test('returns stats for header redaction', () {
        final service = RedactionService();
        final result = service.redactHeadersWithStats({
          'Authorization': 'Bearer secret-token',
          'Content-Type': 'application/json',
        });

        expect(result.headers['Content-Type'], 'application/json');
        expect(result.stats.hasRedactions, isTrue);
        expect(result.stats.keyBased, greaterThan(0));
      });
    });

    group('tokenPrefixRegex coverage', () {
      test('detects OpenAI tokens (sk-)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'sk-proj-abc123def456ghi789jkl012',
        });
        expect(result.stats.hasRedactions, isTrue);
      });

      test('detects Anthropic tokens (sk-ant-)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'sk-ant-api03-abc123def456',
        });
        expect(result.stats.hasRedactions, isTrue);
      });

      test('detects Stripe tokens (sk_live_)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'sk_live_abc123def456ghi789',
        });
        expect(result.stats.hasRedactions, isTrue);
      });

      test('detects AWS access keys (AKIA)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'AKIAIOSFODNN7EXAMPLE',
        });
        expect(result.stats.hasRedactions, isTrue);
      });

      test('detects GitLab PATs (glpat-)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'glpat-xxxxxxxxxxxxxxxxxxxx',
        });
        expect(result.stats.hasRedactions, isTrue);
      });

      test('detects Groq tokens (gsk_)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'gsk_abc123def456ghi789jkl',
        });
        expect(result.stats.hasRedactions, isTrue);
      });

      test('detects npm tokens (npm_)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'npm_abc123def456ghi789jkl',
        });
        expect(result.stats.hasRedactions, isTrue);
      });
    });
  });
}
