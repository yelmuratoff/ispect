import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/secret_metadata.dart';
import 'package:test/test.dart';

void main() {
  group('metadata value patterns', () {
    test('rejects backtracking-prone values within the time bound', () {
      final inputs = <(SecretMetadataQualifier, String)>[
        (SecretMetadataQualifier.version, '${'1' * 31}x'),
        (SecretMetadataQualifier.version, '${'a1' * 15}!'),
        (SecretMetadataQualifier.descriptor, '${'A1-' * 10}!'),
        (SecretMetadataQualifier.descriptor, 'application/${'a' * 19}!'),
        (SecretMetadataQualifier.instant, '2026-10-14T12:00:00.${'1' * 11}!'),
        (SecretMetadataQualifier.quantity, '${'1' * 31}x'),
      ];

      for (final (qualifier, value) in inputs) {
        final stopwatch = Stopwatch()..start();
        final accepted = isSecretMetadataValue(qualifier, value);
        stopwatch.stop();

        expect(accepted, isFalse, reason: value);
        expect(stopwatch.elapsedMilliseconds, lessThan(200), reason: value);
      }
    });

    test('accepts version values', () {
      for (final value in ['4', 's3v4', '1.2.3', 'v2', 'v1.0.0-beta.2']) {
        expect(
          isSecretMetadataValue(SecretMetadataQualifier.version, value),
          isTrue,
          reason: value,
        );
      }
    });

    test('accepts scheme, algorithm, and media type descriptors', () {
      const values = [
        'Bearer',
        'bearer',
        'basic',
        'Basic',
        'RS256',
        'HMAC-SHA1',
        'application/json',
        'jwt',
        'JWT',
        'PKCE',
        'S256',
        'plain',
      ];
      for (final value in values) {
        expect(
          isSecretMetadataValue(SecretMetadataQualifier.descriptor, value),
          isTrue,
          reason: value,
        );
      }
    });

    test('rejects password-shaped descriptors', () {
      for (final value in ['hunter2', 'Summer2024', 'p4ssw0rd', '1234']) {
        expect(
          isSecretMetadataValue(SecretMetadataQualifier.descriptor, value),
          isFalse,
          reason: value,
        );
      }
    });

    test('accepts only boolean values for flag qualifiers', () {
      for (final value in <Object?>[true, false, 'true', 'False', null, 0, 1]) {
        expect(
          isSecretMetadataValue(SecretMetadataQualifier.flag, value),
          isTrue,
          reason: '$value',
        );
      }
      for (final value in <Object?>['1234', '000000', 'yes', 1234, -1, 2.5]) {
        expect(
          isSecretMetadataValue(SecretMetadataQualifier.flag, value),
          isFalse,
          reason: '$value',
        );
      }
    });

    test('masks an email path segment without backtracking blow-up', () {
      final service = RedactionService();
      final text = '/${'a%40' * 200}${'b.' * 200}c';

      final stopwatch = Stopwatch()..start();
      service.redactForExport(text);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
