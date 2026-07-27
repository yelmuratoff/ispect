import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('KeyBasedRedaction', () {
    const strategy = KeyBasedRedaction();

    RedactionContext context({
      Set<String> sensitive = const {'token'},
      Set<String> fullyMasked = const {},
      bool redactBinary = true,
    }) =>
        RedactionContext(
          placeholder: '[REDACTED]',
          redactBinary: redactBinary,
          redactBase64: true,
          sensitiveKeysLower: sensitive,
          sensitiveKeyPatterns: const [],
          fullyMaskedKeyNamesLower: fullyMasked,
          isIgnoredValue: (_) => false,
          isIgnoredKey: (_) => false,
          maskString: (value, {keyName}) => 'MASKED(${value.length})',
          binaryPlaceholder: (len) => '[binary $len bytes]',
          base64Placeholder: (len) => '[base64 ~${len}B]',
          redactUint8List: (data) => Uint8List(data.length),
          looksLikeAuthorizationValue: (_) => false,
          isLikelyBase64: (_) => false,
          isProbablyBinaryString: (_) => false,
        );

    test('masks strings under sensitive keys', () {
      final out = strategy.tryRedact(
        'super-secret',
        context: context(),
        keyName: 'token',
      );
      expect(out, 'MASKED(12)');
    });

    test('fully masks configured keys even when not sensitive', () {
      final out = strategy.tryRedact(
        'report.pdf',
        context: context(
          fullyMasked: const {'filename'},
        ),
        keyName: 'filename',
      );
      expect(out, '[REDACTED]');
    });

    test('fully masks configured keys that are also sensitive', () {
      final out = strategy.tryRedact(
        'apivalue',
        context: context(
          fullyMasked: const {'apikey'},
          sensitive: const {'apikey'},
        ),
        keyName: 'apiKey',
      );
      expect(out, '[REDACTED]');
    });

    test('fully masks scalar, structured, and binary values', () {
      final ctx = context(
        sensitive: const {},
        fullyMasked: const {'opaque'},
      );

      for (final value in <Object?>[
        12345,
        const {'nested': 'value'},
        const ['value'],
        Uint8List.fromList([1, 2, 3]),
      ]) {
        expect(
          strategy.tryRedact(
            value,
            context: ctx,
            keyName: 'opaque',
          ),
          '[REDACTED]',
          reason: value.runtimeType.toString(),
        );
      }
    });

    test('redacts binary Uint8List when enabled', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final out = strategy.tryRedact(
        data,
        context: context(),
        keyName: 'token',
      );
      expect(out, isA<Uint8List>());
      expect((out! as Uint8List).length, 3);
    });

    test('returns placeholder for non-string non-bytes under sensitive key',
        () {
      final out = strategy.tryRedact(
        12345,
        context: context(),
        keyName: 'token',
      );
      expect(out, '[REDACTED]');
    });

    test('returns null when key is not sensitive and not fully masked', () {
      final out = strategy.tryRedact(
        'value',
        context: context(),
        keyName: 'notSensitive',
      );
      expect(out, isNull);
    });

    test('returns null when keyName is null', () {
      final out = strategy.tryRedact(
        'value',
        context: context(),
      );
      expect(out, isNull);
    });

    test('classifyKey matches camelCase keys via snake_case canonicalization',
        () {
      final ctx = context(
        sensitive: const {'access_token'},
        fullyMasked: const {'api_key'},
      );
      expect(ctx.classifyKey('accessToken').sensitive, isTrue);
      expect(ctx.classifyKey('apiKey').fullyMasked, isTrue);
    });

    test('classifyKey normalizes bracketed structural keys', () {
      final ctx = context(
        sensitive: const {'auth_token', 'user_password', 'access_token'},
        fullyMasked: const {'token', 'password'},
      );

      expect(ctx.classifyKey('auth[token]').sensitive, isTrue);
      expect(ctx.classifyKey('user[password]').sensitive, isTrue);
      expect(ctx.classifyKey('access_token[]').sensitive, isTrue);
      expect(ctx.classifyKey('auth[token]').fullyMasked, isTrue);
      expect(ctx.classifyKey('user[password]').fullyMasked, isTrue);
    });

    test('classifyKey matches contiguous composite key segments', () {
      final ctx = context(
        sensitive: const {
          'authorization',
          'cookie',
          'first_name',
          'passport_number',
          'billing_address',
        },
        fullyMasked: const {
          'first_name',
          'passport_number',
          'billing_address',
        },
      );

      expect(ctx.classifyKey('headers[Authorization]').sensitive, isTrue);
      expect(ctx.classifyKey('requestCookie').sensitive, isTrue);
      expect(ctx.classifyKey('customerFirstName').fullyMasked, isTrue);
      expect(ctx.classifyKey('accountPassportNumber').fullyMasked, isTrue);
      expect(
        ctx.classifyKey('checkoutBillingAddressLine1').fullyMasked,
        isTrue,
      );
    });

    test('classifyKey agrees with isSensitiveKey and isFullyMaskedKey', () {
      final ctx = context(
        sensitive: const {'access_token'},
        fullyMasked: const {'api_key'},
      );
      for (final key in ['accessToken', 'apiKey', 'plain']) {
        final c = ctx.classifyKey(key);
        expect(c.sensitive, ctx.isSensitiveKey(key), reason: key);
        expect(c.fullyMasked, ctx.isFullyMaskedKey(key), reason: key);
      }
    });

    test('fully masks a camelCase key matched by canonical form', () {
      final out = strategy.tryRedact(
        'value',
        context: context(fullyMasked: const {'api_key'}),
        keyName: 'apiKey',
      );
      expect(out, '[REDACTED]');
    });
  });
}
