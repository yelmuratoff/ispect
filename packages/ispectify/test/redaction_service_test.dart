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
        final result =
            service.redactUrl('https://user:pass@example.com/path');
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
  });
}
