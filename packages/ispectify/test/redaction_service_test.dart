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
      final service = RedactionService()..ignoreValue('SAFE');

      final map = service.redact({'token': 'SAFE'}) as Map<String, Object?>?;
      expect(map, isNotNull);
      expect(map!['token'], 'SAFE');
    });

    test('fully masks configured keys', () {
      final service = RedactionService(fullyMaskedKeys: {'apiKey'});
      final map =
          service.redact({'apiKey': '123456789'}) as Map<String, Object?>?;
      expect(map, isNotNull);
      expect(map!['apiKey'], '[REDACTED]');
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
  });
}
