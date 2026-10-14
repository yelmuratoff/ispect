// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/redaction/constants/credential_markers.dart';
import 'package:ispectify/src/redaction/scrub/export_string_scrubber.dart';
import 'package:test/test.dart';

const _secret = 'S3cr3tValue0123456789';

void main() {
  tearDown(ISpectRedaction.reset);

  group('concatenated credential keys', () {
    test('fully masks separator-less credential keys in structured data', () {
      final service = RedactionService();
      const keys = [
        'accesstoken',
        'authtoken',
        'refreshtoken',
        'idtoken',
        'sessiontoken',
        'bearertoken',
        'csrftoken',
        'xsrftoken',
        'clientsecret',
        'apisecret',
        'sessionid',
        'jsessionid',
        'phpsessid',
        'sig',
      ];

      final out = service.redact({for (final key in keys) key: _secret})!
          as Map<String, Object?>;

      for (final key in keys) {
        expect(out[key], '[REDACTED]', reason: key);
      }
    });

    test('masks unlisted separator-less token, secret, and session keys', () {
      final service = RedactionService();
      const keys = [
        'continuationtoken',
        'appsecret',
        'aspnetsessionid',
        'ASPSESSIONIDQQGGQGPA',
        'websessid',
      ];

      final out = service.redact({for (final key in keys) key: _secret})!
          as Map<String, Object?>;

      for (final key in keys) {
        expect(out[key], isNot(contains(_secret)), reason: key);
        expect(out[key], contains('[REDACTED]'), reason: key);
      }
    });

    test('masks pagination tokens like the separated next_page_token', () {
      final service = RedactionService();

      final out = service.redact({
        'next_page_token': _secret,
        'nextPageToken': _secret,
        'nexttoken': _secret,
      })! as Map<String, Object?>;

      for (final value in out.values) {
        expect(value, isNot(contains(_secret)));
      }
    });

    test('masks separator-less credential query parameters', () {
      final service = RedactionService();

      final out = service.redactUrl(
        'https://store.example.com/blob?accesstoken=$_secret'
        '&jsessionid=$_secret&sig=$_secret&sv=2024-11-04&page=2',
      );

      expect(out, isNot(contains(_secret)));
      expect(out, contains('sv=2024-11-04'));
      expect(out, contains('page=2'));
    });

    test('masks separator-less credential keys in exported JSON text', () {
      final service = RedactionService();

      final out = service.redactForExport(
        '{"clientsecret": "$_secret", "phpsessid": "$_secret", "page": 2}',
      )! as String;

      expect(out, isNot(contains(_secret)));
      expect(out, contains('"page": 2'));
    });

    test('masks separator-less credential keys with the static export scrub',
        () {
      final out = RedactionService.redactExportString(
        'callback accesstoken=$_secret sig=$_secret page=2',
        defaultSensitiveKeys,
      );

      expect(out, isNot(contains(_secret)));
      expect(out, contains('page=2'));
    });

    test('keeps lookalike non-credential keys visible', () {
      final service = RedactionService();
      final input = <String, Object?>{
        'tokenizer': 'bert-base-uncased',
        'tokens_used': 1200,
        'tokenCount': 3,
        'max_tokens': 512,
        'secretary': 'front-desk',
        'signature_version': '4',
        'signatureVersion': 's3v4',
        'oauth_signature_method': 'HMAC-SHA1',
        'signal': 'strong',
        'sigma': 0.5,
        'design': 'compact',
      };

      expect(service.redact(input), input);
    });

    test('matches sig only as the whole key or the trailing segment', () {
      final service = RedactionService();

      final out = service.redact({
        'sig': 'abc',
        'x_sig': 'abc',
        'urlSig': 'abc',
        'is_sig_valid': true,
        'config_sig_enabled_flag': 'on',
      })! as Map<String, Object?>;

      expect(out['sig'], '[REDACTED]');
      expect(out['x_sig'], '[REDACTED]');
      expect(out['urlSig'], '[REDACTED]');
      expect(out['is_sig_valid'], true);
      expect(out['config_sig_enabled_flag'], 'on');
      expect(
        service.redactUrl('https://cdn.example.com/a?sig=abc&is_sig_valid=1'),
        allOf(isNot(contains('sig=abc')), contains('is_sig_valid=1')),
      );
      expect(
        RedactionService.redactExportString(
          'sig=abc x_sig=abc is_sig_valid=yes',
          defaultSensitiveKeys,
        ),
        allOf(
          isNot(contains('sig=abc')),
          contains('is_sig_valid=yes'),
        ),
      );
    });

    test('keeps lookalike query parameters visible', () {
      final service = RedactionService();
      const url = 'https://api.example.com/v1/complete'
          '?tokenizer=bpe&max_tokens=512&signature_version=4&signal=on';

      expect(service.redactUrl(url), url);
    });
  });

  group('metadata under sensitive keys', () {
    test('keeps boolean and expiry metadata under sensitive key segments', () {
      final service = RedactionService();
      final input = <String, Object?>{
        'email_verified': true,
        'emailVerified': true,
        'phone_verified': false,
        'phone_number_verified': true,
        'login_required': true,
        'has_password': true,
        'password_set': true,
        'mfa_enabled': true,
        'otp_enabled': false,
        'token_expires_in': 3600,
        'access_token_expires_at': '2026-10-14T12:00:00Z',
        'refresh_token_ttl': 86400,
      };

      expect(service.redact(input), input);
    });

    test('keeps metadata query parameters visible', () {
      final service = RedactionService();

      final out = service.redactUrl(
        'https://auth.example.com/cb?email_verified=true'
        '&token_expires_in=3600&access_token=$_secret',
      );

      expect(out, contains('email_verified=true'));
      expect(out, contains('token_expires_in=3600'));
      expect(out, isNot(contains(_secret)));
    });

    test('keeps metadata assignments visible in the static export scrub', () {
      final out = RedactionService.redactExportString(
        'email_verified=true password=$_secret token_type=Bearer',
        defaultSensitiveKeys,
      );

      expect(out, contains('token_type=Bearer'));
      expect(out, contains('email_verified=true'));
      expect(out, isNot(contains(_secret)));
    });

    test('masks structured and secret-shaped values under metadata keys', () {
      final service = RedactionService();

      final out = service.redact({
        'secretVersion': {
          'payload': {'data': 'aHVudGVyMg=='},
        },
        'password_set': 'N3wPass!',
        'credentialSet': {'user': 'bob', 'value': 'hunter2'},
        'api_key_set': ['x'],
        'password_version': 'hunter2',
        'token_type': 'ghp_ABCDEFGHIJKLMNOP1234',
      })! as Map<String, Object?>;

      expect(out['secretVersion'], '[REDACTED]');
      expect(out['password_set'], '[REDACTED]');
      expect(out['credentialSet'], '[REDACTED]');
      expect(out['api_key_set'], '[REDACTED]');
      expect(out['password_version'], '[REDACTED]');
      expect(out['token_type'], isNot(contains('ghp_ABCDEFGHIJKLMNOP1234')));
    });

    test('keeps scalar and descriptor metadata values visible', () {
      final service = RedactionService();
      final input = <String, Object?>{
        'email_verified': true,
        'token_expires_in': 3600,
        'token_type': 'Bearer',
        'has_password': true,
        'mfa_enabled': false,
        'password_set': true,
        'oauth_signature_method': 'HMAC-SHA1',
        'token_algorithm': 'RS256',
        'authorization_scheme': 'basic',
        'signature_version': '4',
        'signatureVersion': 's3v4',
        'refresh_token_count': null,
      };

      expect(service.redact(input), input);
    });

    test('masks password-shaped descriptors and numeric flag strings', () {
      final service = RedactionService();

      final out = service.redact({
        'password_type': 'hunter2',
        'credential_format': 'Summer2024',
        'password_set': '1234',
        'email_verified': '123456',
        'token_type': 'bearer',
        'token_format': 'JWT',
      })! as Map<String, Object?>;

      expect(out['password_type'], '[REDACTED]');
      expect(out['credential_format'], '[REDACTED]');
      expect(out['password_set'], '[REDACTED]');
      expect(out['email_verified'], isNot('123456'));
      expect(out['token_type'], 'bearer');
      expect(out['token_format'], 'JWT');
      expect(
        RedactionService.redactExportString(
          'credential_format=Summer2024 password_set=1234 token_type=Bearer',
          defaultSensitiveKeys,
        ),
        allOf(
          isNot(contains('Summer2024')),
          isNot(contains('1234')),
          contains('token_type=Bearer'),
        ),
      );
    });

    test('skips the metadata value check for qualifier keys without a secret',
        () {
      final service = RedactionService();
      final input = <String, Object?>{
        'app_version': '${'1' * 30}x',
        'content_type': 'application/json',
        'item_count': '42',
      };

      final stopwatch = Stopwatch()..start();
      final out = service.redact(input);
      stopwatch.stop();

      expect(out, input);
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('masks secret values under metadata keys in URLs and free text', () {
      final service = RedactionService();
      const url = 'https://x.example.com/reset?password_set=hunter2';
      const text = 'reset failed: password_set=hunter2 for user';

      expect(service.redactUrl(url), isNot(contains('hunter2')));
      expect(service.redactForExport(text), isNot(contains('hunter2')));
      expect(
        RedactionService.redactExportString(text, defaultSensitiveKeys),
        isNot(contains('hunter2')),
      );
      expect(
        RedactionService.redactExportString(
          'GET $url failed',
          defaultSensitiveKeys,
        ),
        isNot(contains('hunter2')),
      );
      expect(
        ExportStringScrubber.scrub(
          'GET http://[bad/reset?password_set=hunter2',
          ExportStringScrubber.patternsFor(defaultSensitiveKeys),
        ),
        isNot(contains('hunter2')),
      );
    });

    test('keeps literal metadata values visible in free text', () {
      final service = RedactionService();
      const text = 'token_expires_in=3600 email_verified=true '
          'password_set=false token_type=Bearer';

      expect(service.redactForExport(text), text);
      expect(
        RedactionService.redactExportString(text, defaultSensitiveKeys),
        text,
      );
      expect(
        service.redactForExport('{"token_type": "Bearer", "password": "x"}'),
        allOf(contains('"token_type": "Bearer"'), isNot(contains('"x"'))),
      );
    });

    test('still masks credentials and identifiers beside the metadata', () {
      final service = RedactionService();

      final out = service.redact({
        'password': 'x',
        'password_reset_token': _secret,
        'email': 'alice@example.com',
        'phone': 5551234,
        'pin_code': 1234,
        'otp_code': '123456',
      })! as Map<String, Object?>;

      expect(out['password'], '[REDACTED]');
      expect(out['password_reset_token'], '[REDACTED]');
      expect(out['email'], isNot(contains('alice@example.com')));
      expect(out['phone'], '[REDACTED]');
      expect(out['pin_code'], '[REDACTED]');
      expect(out['otp_code'], '[REDACTED]');
    });

    test('masks booleans under fully masked keys', () {
      final service = RedactionService();

      final out = service.redact({'password': true, 'gender': false})!
          as Map<String, Object?>;

      expect(out['password'], '[REDACTED]');
      expect(out['gender'], '[REDACTED]');
    });

    test('KeyBasedRedaction leaves booleans under edge-masked keys untouched',
        () {
      final context = RedactionContext(
        placeholder: '[REDACTED]',
        redactBinary: true,
        redactBase64: true,
        sensitiveKeysLower: const {'email', 'password'},
        sensitiveKeyPatterns: const [],
        fullyMaskedKeyNamesLower: const {'password'},
        isIgnoredValue: (_) => false,
        isIgnoredKey: (_) => false,
        maskString: (value, {keyName}) => 'MASKED',
        binaryPlaceholder: (len) => '[binary]',
        base64Placeholder: (len) => '[base64]',
        redactUint8List: (data) => Uint8List(data.length),
        looksLikeAuthorizationValue: (_) => false,
        isLikelyBase64: (_) => false,
        isProbablyBinaryString: (_) => false,
      );
      const strategy = KeyBasedRedaction();

      expect(
        strategy.tryRedact(true, context: context, keyName: 'email'),
        isNull,
      );
      expect(
        strategy.tryRedact(1, context: context, keyName: 'email'),
        '[REDACTED]',
      );
      expect(
        strategy.tryRedact(true, context: context, keyName: 'password'),
        '[REDACTED]',
      );
    });
  });

  group('value-less key classification', () {
    test('a custom strategy using isSensitiveKey masks metadata-key containers',
        () {
      final service = RedactionService(strategy: const _SensitiveKeyStrategy());

      final out = service.redact({
        'password_set': {'value': 'hunter2'},
        'token_type': ['hunter2'],
      });

      expect(out.toString(), isNot(contains('hunter2')));
    });

    test('classifies metadata keys by their sensitive stem', () {
      final context = RedactionContext(
        placeholder: '[REDACTED]',
        redactBinary: true,
        redactBase64: true,
        sensitiveKeysLower: const {'token'},
        sensitiveKeyPatterns: [RegExp('password')],
        fullyMaskedKeyNamesLower: const {'password'},
        isIgnoredValue: (_) => false,
        isIgnoredKey: (_) => false,
        maskString: (value, {keyName}) => 'MASKED',
        binaryPlaceholder: (len) => '[binary]',
        base64Placeholder: (len) => '[base64]',
        redactUint8List: (data) => Uint8List(data.length),
        looksLikeAuthorizationValue: (_) => false,
        isLikelyBase64: (_) => false,
        isProbablyBinaryString: (_) => false,
      );

      expect(
        context.classifyKey('password_set'),
        (fullyMasked: true, sensitive: true),
      );
      expect(context.isSensitiveKey('token_type'), isTrue);
      expect(context.isFullyMaskedKey('password_set'), isTrue);
      expect(context.isSensitiveKeyLower('password_set'), isTrue);
      expect(
        context.classifyEntry('password_set', true),
        (fullyMasked: false, sensitive: false),
      );
    });
  });

  group('default key sets', () {
    test('only contact, auth-header, and cookie keys keep edge masking', () {
      expect(defaultSensitiveKeys.difference(defaultFullyMaskedKeys), {
        'authorization',
        'proxy-authorization',
        'set-cookie',
        'cookie',
        'email',
        'e-mail',
        'email_address',
        'username',
        'user_name',
        'login',
        'phone',
        'phone_number',
        'phonenumber',
        'phone-number',
        'mobile_number',
        'mobilenumber',
        'mobile-number',
        'mobile_phone',
        'mobilephone',
        'mobile-phone',
        'cell_phone',
        'cellphone',
        'cell-phone',
        'cell_number',
        'cellnumber',
        'cell-number',
      });
    });

    test('fully masks postal details and card expiry', () {
      final service = RedactionService();
      const keys = [
        'postal_code',
        'postalCode',
        'zip_code',
        'zipcode',
        'street_address',
        'streetAddress',
        'card_expire',
        'cardexpire',
      ];

      final out =
          service.redact({for (final key in keys) key: 'SW1A 1AA 12/29'})!
              as Map<String, Object?>;

      for (final key in keys) {
        expect(out[key], '[REDACTED]', reason: key);
      }
    });

    test('keeps edge masking for contact fields', () {
      final service = RedactionService();

      final out = service.redact({'email': 'alice@example.com'})!
          as Map<String, Object?>;

      expect(out['email'], 'al…om ([REDACTED])');
    });
  });

  group('token prefix and auth scheme markers', () {
    test('every known token prefix triggers scrubbing and is masked', () {
      final prefixes = [...knownTokenPrefixes, awsAccessKeyIdPrefix];
      for (final prefix in prefixes) {
        final token = '${prefix}ABCDEFGHIJKLMNOP1234';
        for (final text in [token, 'leaked $token in log']) {
          expect(
            ExportStringScrubber.requiresScrub(text),
            isTrue,
            reason: text,
          );
          expect(
            ExportStringScrubber.scrub(text, null),
            isNot(contains(token)),
            reason: text,
          );
        }
        expect(tokenPrefixRegex.hasMatch(token), isTrue, reason: token);
      }
    });

    test('every auth scheme triggers scrubbing and is masked', () {
      final schemes = [...httpAuthSchemes, '${scramAuthSchemePrefix}256'];
      for (final scheme in schemes) {
        final text = 'retry with $scheme $_secret';
        expect(
          ExportStringScrubber.requiresScrub(text),
          isTrue,
          reason: scheme,
        );
        expect(
          ExportStringScrubber.scrub(text, null),
          isNot(contains(_secret)),
          reason: scheme,
        );
        expect(
          schemeRegex.hasMatch('$scheme $_secret'),
          isTrue,
          reason: scheme,
        );
      }
    });

    test('plain text without markers skips scrubbing', () {
      expect(ExportStringScrubber.requiresScrub('HomeScreen'), isFalse);
      expect(ExportStringScrubber.requiresScrub('akin'), isFalse);
    });
  });
}

final class _SensitiveKeyStrategy implements RedactionStrategy {
  const _SensitiveKeyStrategy();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      context.isSensitiveKey(keyName) ? context.placeholder : null;
}
