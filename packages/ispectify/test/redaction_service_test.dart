import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _ThrowingStrategy implements RedactionStrategy {
  const _ThrowingStrategy();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      throw StateError('boom');
}

final class _HostileStrategyValue {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('HOSTILE_STRATEGY_FORMATTER');
  }
}

final class _ReturningStrategy implements RedactionStrategy {
  const _ReturningStrategy(this.value);

  final Object? value;

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      value;
}

final class _ThrowingExportValue {
  const _ThrowingExportValue();

  @override
  String toString() => throw StateError('must not escape');
}

final class _ThrowingExportKey {
  const _ThrowingExportKey();

  @override
  String toString() => throw StateError('must not escape');
}

final class _HostileMapKey {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('must not escape');
  }
}

final class _HostileExportDto {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    return 'HOSTILE-EXPORT-DTO-SECRET';
  }

  @override
  String toString() {
    toStringCalls++;
    return 'HOSTILE-EXPORT-DTO-SECRET';
  }
}

final class _UnboundedExportIterable extends Iterable<int> {
  @override
  Iterator<int> get iterator => _UnboundedExportIterator();
}

final class _UnboundedExportIterator implements Iterator<int> {
  var _current = -1;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    _current++;
    return true;
  }
}

void main() {
  tearDown(ISpectRedaction.reset);

  group('RedactionService', () {
    test('exposes ignore-list mutations through its configuration revision',
        () {
      final service = RedactionService();

      expect(service.configurationRevision, 0);
      service.ignoreValue('public-example');
      expect(service.configurationRevision, 1);
      service.ignoreKey('public_field');
      expect(service.configurationRevision, 2);
      service.unignoreValue('public-example');
      expect(service.configurationRevision, 3);
      service.unignoreKey('public_field');
      expect(service.configurationRevision, 4);
    });

    test('propagates a strategy error so boundary callers fail closed', () {
      // The walker is fail-loud by design: it does not swallow a throwing
      // strategy. Boundary callers (NetworkRedactionMixin) catch and fail
      // closed to a placeholder while logging a warning.
      final service = RedactionService(strategy: const _ThrowingStrategy());
      expect(
        () => service.redact({'password': 'secret'}),
        throwsA(isA<StateError>()),
      );
    });

    test('hoisted default lower sets equal the lowercased defaults', () {
      expect(
        defaultSensitiveKeysLower,
        defaultSensitiveKeys.map((e) => e.toLowerCase()).toSet(),
      );
      expect(
        defaultFullyMaskedKeysLower,
        defaultFullyMaskedKeys.map((e) => e.toLowerCase()).toSet(),
      );
    });

    test('default-constructed service redacts same as explicit default keys',
        () {
      final auto = RedactionService();
      final explicit = RedactionService(
        sensitiveKeys: defaultSensitiveKeys,
        fullyMaskedKeys: defaultFullyMaskedKeys,
      );
      final input = <String, Object?>{
        'password': 'p',
        'accessToken': 'a',
        'keep': 'v',
      };
      expect(auto.redact(input), explicit.redact(input));
    });

    test('additional sensitive keys preserve default key protection', () {
      final service = RedactionService(
        additionalSensitiveKeys: const {'business_marker'},
      );

      final result = service.redact(
        const {
          'password': 'default-secret',
          'business_marker': 'domain-secret',
        },
      );

      final map = result! as Map<String, Object?>;
      expect(map['password'], defaultPlaceholder);
      expect(map['business_marker'], isNot('domain-secret'));
      expect(map['business_marker'], contains(defaultPlaceholder));
    });

    test('additional key patterns preserve default key protection', () {
      final service = RedactionService(
        additionalSensitiveKeyPatterns: [
          RegExp(r'^business_marker_\d+$'),
        ],
      );

      final result = service.redact(
        const {
          'password': 'default-secret',
          'business_marker_42': 'domain-secret',
        },
      );

      final map = result! as Map<String, Object?>;
      expect(map['password'], defaultPlaceholder);
      expect(map['business_marker_42'], isNot('domain-secret'));
      expect(map['business_marker_42'], contains(defaultPlaceholder));
    });

    test('does not format unknown map keys and fails closed', () {
      final key = _HostileMapKey();
      final result = RedactionService().redact({
        key: 'secret-behind-unknown-key',
        'safe': 'visible',
      })! as Map<String, Object?>;

      expect(key.toStringCalls, 0);
      expect(result['<unprintable-key>'], defaultPlaceholder);
      expect(result['safe'], 'visible');
      expect(result.toString(), isNot(contains('secret-behind-unknown-key')));
    });

    test('redacts personal PII keys by default', () {
      final service = RedactionService();
      final out = service.redact({
        'firstName': 'Emily',
        'last_name': 'Johnson',
        'gender': 'female',
        'nationality': 'United States',
        'home_address': '1 Main Street',
        'tax_id': '123-45-6789',
        'birthday': '1990-01-01',
        'keep': 'visible',
      })! as Map<String, Object?>;

      expect(out['firstName'], '[REDACTED]');
      expect(out['last_name'], '[REDACTED]');
      expect(out['gender'], '[REDACTED]');
      expect(out['nationality'], '[REDACTED]');
      expect(out['home_address'], '[REDACTED]');
      expect(out['tax_id'], '[REDACTED]');
      expect(out['birthday'], '[REDACTED]');
      expect(out['keep'], 'visible');
    });

    test('redacts newly-added credential/session keys by default', () {
      final service = RedactionService();
      final out = service.redact({
        'session': 'sess-abcdef123456',
        'passphrase': 'correct horse battery',
        'credentials': 'root:toor',
        'pincode': '4821',
        'keep': 'visible',
      })! as Map<String, Object?>;

      expect(out['session'], '[REDACTED]');
      expect(out['passphrase'], '[REDACTED]');
      expect(out['credentials'], '[REDACTED]');
      expect(out['pincode'], '[REDACTED]');
      expect(out['keep'], 'visible');
    });

    test('does not redact ambiguous non-PII keys by default', () {
      final service = RedactionService();
      final out = service.redact({
        'name': 'Checkout Screen',
        'age': 42,
        'address': 'Main Office',
        'location': 'Dashboard View',
      })! as Map<String, Object?>;

      expect(out['name'], 'Checkout Screen');
      expect(out['age'], 42);
      expect(out['address'], 'Main Office');
      expect(out['location'], 'Dashboard View');
    });

    test('redacts sensitive headers by default', () {
      final service = RedactionService();
      final headers = service.redactHeaders({
        'Authorization': 'Bearer secret-token',
        'X-Custom': 'visible',
      });

      expect(headers['Authorization'], contains('[REDACTED]'));
      expect(headers['X-Custom'], 'visible');
    });

    test('scrubs data embedded in header names and arbitrary values', () {
      const rawName = 'sk-DIRECTHEADERNAMESECRET123456';
      const valueSecret = 'DIRECT-ARBITRARY-HEADER-VALUE';
      const cookieNameSecret = 'sk-DIRECT-COOKIE-NAME-SECRET-123456';
      final service = RedactionService();

      final headers = service.redactHeaders({
        rawName: 'password=$valueSecret',
        'Cookie': '$cookieNameSecret=value',
      });

      expect(headers.keys, contains(defaultPlaceholder));
      expect(headers.toString(), isNot(contains(rawName)));
      expect(headers.toString(), isNot(contains(valueSecret)));
      expect(headers.toString(), isNot(contains(cookieNameSecret)));
    });

    test('respects per-call ignored keys', () {
      final service = RedactionService();
      final headers = service.redactHeaders(
        {'Authorization': 'Bearer explicitly-visible-secret'},
        ignoredKeys: {'Authorization'},
      );

      expect(
        headers['Authorization'],
        'Bearer explicitly-visible-secret',
      );
    });

    test('respects per-call ignored header values', () {
      const ignored = 'Bearer explicitly-visible-value';
      final service = RedactionService();
      final headers = service.redactHeaders(
        {'X-Debug': ignored},
        ignoredValues: {ignored},
      );

      expect(headers['X-Debug'], ignored);
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
      expect(redacted, '[binary 16 bytes]'.codeUnits);
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
        // A plain value with no token/scheme/base64 shape, so only a key match
        // (after trimming) can redact it — isolates the whitespace handling.
        final map = service.redact({
          'password ': 'plainvalue123',
        })! as Map<String, Object?>;

        expect(map['password '], '[REDACTED]');
      });

      test('leaves non-sensitive camelCase keys untouched', () {
        final service = RedactionService();
        final map = service.redact({
          'sortOrder': 'ascending',
          'createdAt': '2026-01-01',
          'itemKeyboard': 'visible',
        })! as Map<String, Object?>;

        expect(map['sortOrder'], 'ascending');
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

      test('does not whitelist log-type words used as credentials', () {
        final service = RedactionService();
        final result = service.redact({
          'password': 'debug',
          'token': 'provider',
          'secret': 'info',
        })! as Map<String, Object?>;
        final exported = service.redactForExport({
          'password': 'debug',
          'token': 'provider',
          'secret': 'info',
        })! as Map<String, Object?>;

        for (final key in const ['password', 'token', 'secret']) {
          expect(result[key], defaultPlaceholder);
          expect(exported[key], defaultPlaceholder);
        }
      });

      test('custom full-mask keys extend the credential-safe defaults', () {
        final service = RedactionService(
          fullyMaskedKeys: const {'filename'},
          visibleEdgeLength: 3,
        );
        final result = service.redact({
          'filename': 'private.txt',
          'password': 'PASSWORD_PREFIX_secret_PASSWORD_SUFFIX',
          'token': 'TOKEN_PREFIX_secret_TOKEN_SUFFIX',
        })! as Map<String, Object?>;

        expect(result['filename'], defaultPlaceholder);
        expect(result['password'], defaultPlaceholder);
        expect(result['token'], defaultPlaceholder);
      });

      test('fully masks sensitive subsequences in composite keys', () {
        final result = RedactionService().redact({
          'customerFirstName': 'COMPOSITE_FIRST_NAME_SECRET',
          'accountPassportNumber': 'COMPOSITE_PASSPORT_SECRET',
          'checkoutBillingAddressLine1': 'COMPOSITE_ADDRESS_SECRET',
        })! as Map<String, Object?>;

        expect(result['customerFirstName'], defaultPlaceholder);
        expect(result['accountPassportNumber'], defaultPlaceholder);
        expect(result['checkoutBillingAddressLine1'], defaultPlaceholder);
      });

      test('uses header-aware masking for composite header keys', () {
        final result = RedactionService().redact({
          'headers[Authorization]': 'DPoP BRACKET_AUTHORIZATION_SECRET',
          'requestAuthorization': 'GNAP CAMEL_AUTHORIZATION_SECRET',
          'headers.Cookie': 'session=BRACKET_COOKIE_SECRET',
          'responseSetCookie': 'session=CAMEL_SET_COOKIE_SECRET',
          'userUsername': 'CAMEL_USERNAME_SECRET',
        })! as Map<String, Object?>;

        expect(
          result['headers[Authorization]'],
          'DPoP $defaultPlaceholder',
        );
        expect(
          result['requestAuthorization'],
          'GNAP $defaultPlaceholder',
        );
        expect(
          result['headers.Cookie'],
          isNot(contains('BRACKET_COOKIE_SECRET')),
        );
        expect(
          result['responseSetCookie'],
          isNot(contains('CAMEL_SET_COOKIE_SECRET')),
        );
        expect(
          result['userUsername'],
          isNot(contains('CAMEL_USERNAME_SECRET')),
        );
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

        expect(result['authorization'], '[REDACTED]');
        expect(result['safe'], 'visible');
      });

      test('matches lowercase keys against mixed-case data keys', () {
        final result = RedactionService.redactByKeys(
          {'Authorization': 'Bearer secret'},
          {'authorization'},
        )! as Map<String, Object?>;

        expect(result['Authorization'], '[REDACTED]');
      });

      test('fails closed with a placeholder past the depth limit', () {
        Object? nested = {'password': 'secret'};
        for (var i = 0; i < 3; i++) {
          nested = {'level': nested};
        }
        final result = RedactionService.redactByKeys(
          nested,
          {'password'},
          maxDepth: 2,
        );
        expect('$result', isNot(contains('secret')));
      });

      test('does not format unknown map keys and fails closed', () {
        final key = _HostileMapKey();
        final result = RedactionService.redactByKeys(
          {key: 'secret-behind-unknown-key', 'safe': 'visible'},
          {'password'},
        )! as Map<String, Object?>;

        expect(key.toStringCalls, 0);
        expect(result['<unprintable-key>'], defaultPlaceholder);
        expect(result['safe'], 'visible');
        expect(result.toString(), isNot(contains('secret-behind-unknown-key')));
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

      test('returns unparseable URL unchanged when nothing is sensitive', () {
        final service = RedactionService();
        const bad = ':::not-a-url';
        expect(service.redactUrl(bad), bad);
      });

      test('sanitizes credentials and sensitive params in an unparseable URL',
          () {
        final service = RedactionService();
        const malformed = 'ht!tp://user:pass@host/path?token=secret';
        final result = service.redactUrl(malformed);
        expect(result, isNot(contains('user:pass')));
        expect(result, isNot(contains('secret')));
      });

      test('redacts sensitive values in the URL fragment (implicit-grant)', () {
        final service = RedactionService();
        final result = service.redactUrl(
          'https://app.example.com/callback#access_token=abc123&id_token=xyz789',
        );
        expect(result, isNot(contains('abc123')));
        expect(result, isNot(contains('xyz789')));
        expect(result, contains('access_token='));
      });

      test('redacts query values inside SPA hash routes', () {
        for (final path in const ['#/callback', '#!/callback']) {
          final result = RedactionService().redactUrl(
            'https://app.test/$path'
            '?access_token=HASH_ROUTE_SECRET&safe=visible',
          );

          expect(result, isNot(contains('HASH_ROUTE_SECRET')));
          expect(result, contains('safe=visible'));
          expect(Uri.decodeFull(result), contains(defaultPlaceholder));
        }
      });

      test('redacts single and double encoded SPA hash routes', () {
        for (var encodePasses = 1; encodePasses <= 2; encodePasses++) {
          var fragment = '/callback?token=ENCODED_FRAGMENT_SECRET&safe=visible';
          for (var index = 0; index < encodePasses; index++) {
            fragment = Uri.encodeQueryComponent(fragment);
          }

          final result = RedactionService().redactUrl(
            'https://app.test/#$fragment',
          );
          var decoded = result;
          for (var index = 0; index < 3; index++) {
            decoded = Uri.decodeFull(decoded);
          }

          expect(decoded, isNot(contains('ENCODED_FRAGMENT_SECRET')));
          expect(decoded, contains('safe=visible'));
          expect(decoded, contains(defaultPlaceholder));
        }
      });

      test('redacts semicolon-delimited query parameters', () {
        final result = RedactionService().redactUrl(
          'https://api.test/?safe=visible;token=SEMICOLON_QUERY_SECRET',
        );

        expect(result, isNot(contains('SEMICOLON_QUERY_SECRET')));
        expect(result, contains('safe=visible;token='));
      });

      test('redacts percent-encoded query keys', () {
        final result = RedactionService().redactUrl(
          'https://example.com/callback?%74oken=ENCODED_KEY_SECRET&safe=visible',
        );

        expect(result, isNot(contains('ENCODED_KEY_SECRET')));
        expect(Uri.parse(result).queryParameters, contains('token'));
        expect(result, contains('safe=visible'));
      });

      test('redacts bracketed and encoded bracketed query keys', () {
        final result = RedactionService().redactUrl(
          'https://example.com/callback'
          '?auth[token]=AUTH_BRACKET_SECRET'
          '&user%5Bpassword%5D=PASSWORD_BRACKET_SECRET'
          '&access_token%5B%5D=TOKEN_ARRAY_SECRET'
          '&safe=visible',
        );

        expect(result, isNot(contains('AUTH_BRACKET_SECRET')));
        expect(result, isNot(contains('PASSWORD_BRACKET_SECRET')));
        expect(result, isNot(contains('TOKEN_ARRAY_SECRET')));
        expect(result, contains('safe=visible'));
      });

      test('redacts repeatedly encoded query keys', () {
        final result = RedactionService().redactUrl(
          'https://example.com/callback'
          '?%2574oken=DOUBLE_ENCODED_KEY_SECRET',
        );

        expect(result, isNot(contains('DOUBLE_ENCODED_KEY_SECRET')));
        expect(result, contains('REDACTED'));
      });

      test('applies custom key patterns to percent-encoded query keys', () {
        final service = RedactionService(
          sensitiveKeys: const {},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
          placeholder: '<URL_POLICY>',
        );

        final result = service.redactUrl(
          'https://example.com/callback'
          '?%74enantCredential=CUSTOM_ENCODED_SECRET',
        );

        expect(result, isNot(contains('CUSTOM_ENCODED_SECRET')));
        expect(
          Uri.parse(result).queryParameters,
          contains('tenantCredential'),
        );
        expect(
          Uri.parse(result).queryParameters['tenantCredential'],
          contains('<URL_POLICY>'),
        );
      });

      test('fails closed for malformed encoded query and fragment keys', () {
        for (final url in const [
          'https://example.com/callback?%ZZ=QUERY_KEY_SECRET',
          'https://example.com/callback#%ZZ=FRAGMENT_KEY_SECRET',
        ]) {
          final result = RedactionService().redactUrl(url);

          expect(Uri.decodeFull(result), contains(defaultPlaceholder));
          expect(result, isNot(contains('KEY_SECRET')));
        }
      });

      test('leaves a non key-value fragment unchanged', () {
        final service = RedactionService();
        const url = 'https://example.com/docs#section-two';
        expect(service.redactUrl(url), url);
      });

      test('redacts secrets inside a percent-encoded nested URL', () {
        final nested = Uri.encodeQueryComponent(
          'https://alice:hunter2@inner.example/path'
          '?token=INNER_URL_SECRET&safe=visible',
        );

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$nested',
        );

        expect(result, isNot(contains('hunter2')));
        expect(result, isNot(contains('INNER_URL_SECRET')));
        expect(Uri.decodeFull(result), contains('safe=visible'));
      });

      test('redacts raw and repeatedly encoded nested form values', () {
        for (var encodePasses = 0; encodePasses <= 2; encodePasses++) {
          var nested = 'token=NESTED_FORM_SECRET_$encodePasses&safe=visible';
          for (var index = 0; index < encodePasses; index++) {
            nested = Uri.encodeQueryComponent(nested);
          }

          final result = RedactionService().redactUrl(
            'https://outer.example/callback?redirect=$nested',
          );
          var decoded = result;
          for (var index = 0; index < 3; index++) {
            decoded = Uri.decodeFull(decoded);
          }

          expect(result, isNot(contains('NESTED_FORM_SECRET')));
          expect(decoded, isNot(contains('NESTED_FORM_SECRET')));
          expect(decoded, contains('safe=visible'));
          expect(decoded, contains(defaultPlaceholder));
        }
      });

      test('redacts uppercase schemes inside encoded nested URLs', () {
        final nested = Uri.encodeQueryComponent(
          'HTTPS://alice:hunter2@inner.example/path'
          '?token=UPPERCASE_SECRET&safe=visible',
        );

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$nested',
        );

        expect(result, isNot(contains('hunter2')));
        expect(result, isNot(contains('UPPERCASE_SECRET')));
        expect(Uri.decodeFull(result), contains('safe=visible'));
      });

      test('redacts secrets inside an encoded relative redirect', () {
        final nested = Uri.encodeQueryComponent(
          '/callback?token=RELATIVE_SECRET&safe=visible',
        );

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$nested',
        );

        expect(result, isNot(contains('RELATIVE_SECRET')));
        expect(Uri.decodeFull(result), contains('safe=visible'));
      });

      test('redacts secrets inside an encoded protocol-relative redirect', () {
        final nested = Uri.encodeQueryComponent(
          '//inner.example/callback?token=PROTOCOL_SECRET&safe=visible',
        );

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$nested',
        );

        expect(result, isNot(contains('PROTOCOL_SECRET')));
        expect(Uri.decodeFull(result), contains('safe=visible'));
      });

      test('fails closed when nested URL decoding exceeds its budget', () {
        var nested = 'https://inner.example/path?token=OVER_ENCODED_SECRET';
        for (var index = 0; index < 8; index++) {
          nested = Uri.encodeQueryComponent(nested);
        }

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$nested',
        );

        expect(result, isNot(contains('OVER_ENCODED_SECRET')));
        expect(Uri.decodeFull(result), contains(defaultPlaceholder));
      });

      test('bounds cumulative recursion across nested redirect URLs', () {
        var nested = 'https://leaf.example/path?token=DEEPLY_NESTED_SECRET';
        for (var index = 0; index < 40; index++) {
          nested = 'https://nested$index.example/callback?redirect=$nested';
        }

        final result = RedactionService().redactUrl(nested);

        expect(result, isNot(contains('DEEPLY_NESTED_SECRET')));
        expect(result, contains('REDACTED'));
        expect(result.length, lessThanOrEqualTo(nested.length * 4 + 1024));
      });

      test('fails closed for malformed encoded redirect components', () {
        const malformed = 'https%3A%2F%2Finner.example%2F%ZZ';

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$malformed',
        );

        expect(Uri.decodeFull(result), contains(defaultPlaceholder));
        expect(result, isNot(contains('inner.example')));
      });

      test('fails closed for malformed encoded relative redirects', () {
        const malformed = '%2Fcallback%3Fsafe%3Dvisible%26token%3Dsecret%ZZ';

        final result = RedactionService().redactUrl(
          'https://outer.example/callback?redirect=$malformed',
        );

        expect(Uri.decodeFull(result), contains(defaultPlaceholder));
        expect(
          Uri.parse(result).queryParameters['redirect'],
          defaultPlaceholder,
        );
      });

      test('preserves a safe encoded literal percent value', () {
        const url = 'https://outer.example/callback?discount=50%25';

        expect(RedactionService().redactUrl(url), url);
      });

      test('keeps an already-redacted malformed component fail closed', () {
        const encoded = 'DI%E2%80%A6%5D%29+%28%5BREDACTED%5D%29';
        const value = 'request https://api.example.com?api_key=$encoded';

        final result = RedactionService().redactForExport(value);

        expect(result, isA<String>());
        expect(result, isNot(defaultPlaceholder));
        expect(result.toString(), isNot(contains('api_key=DI')));
      });
    });

    group('redactExportString', () {
      test('scrubs Bearer tokens even when no keys are provided', () {
        final result = RedactionService.redactExportString(
          'Request failed with header Authorization: Bearer secret-jwt-token',
          null,
        );
        expect(result, isNot(contains('secret-jwt-token')));
      });

      test('scrubs URL credentials even when keys are empty', () {
        final result = RedactionService.redactExportString(
          'connect to https://user:pass@db.internal/path',
          const <String>{},
        );
        expect(result, isNot(contains('user:pass')));
      });

      test('applies key-based query redaction when keys are provided', () {
        final result = RedactionService.redactExportString(
          'GET /api?token=leaked',
          const {'token'},
        );
        expect(result, isNot(contains('leaked')));
        expect(result, contains('token='));
      });

      test('scrubs escape-aware JSON string values completely', () {
        const secret = r'prefix\"still-secret\\tail';
        final result = RedactionService.redactExportString(
          '{"token":"$secret","safe":"visible"}',
          const {'token'},
        );

        expect(result, isNot(contains('still-secret')));
        expect(result, isNot(contains(r'\\tail')));
        expect(result, contains('"token": "[REDACTED]"'));
        expect(result, contains('"safe":"visible"'));
      });

      test('scrubs sensitive assignments embedded in prose', () {
        final result = RedactionService.redactExportString(
          'login failed password=hunter2; retry token: "token-secret"',
          const {'password', 'token'},
        );

        expect(result, isNot(contains('hunter2')));
        expect(result, isNot(contains('token-secret')));
        expect(result, contains('password=$defaultPlaceholder'));
        expect(result, contains('token: $defaultPlaceholder'));
      });

      test('scrubs embedded known-prefix tokens and JWTs in prose', () {
        const prefixedToken = 'ghp_abcdefghijklmnopqrstuvwxyz';
        const fineGrainedToken =
            'github_pat_abcdefghijklmnopqrstuvwxyz0123456789';
        const jwt = 'aaaaaaaaaaa.bbbbbbbbbbb.ccccccccccc';

        final result = RedactionService.redactExportString(
          'request carried $prefixedToken, $fineGrainedToken, and $jwt',
          null,
        );

        expect(result, isNot(contains(prefixedToken)));
        expect(result, isNot(contains(fineGrainedToken)));
        expect(result, isNot(contains(jwt)));
        expect(result, contains(defaultPlaceholder));
      });

      test('scrubs every supported authentication scheme', () {
        for (final scheme in const [
          'Bearer',
          'Basic',
          'Token',
          'Digest',
          'NTLM',
          'Negotiate',
          'OAuth',
          'HOBA',
          'Mutual',
          'SCRAM-SHA-256',
        ]) {
          final result = RedactionService.redactExportString(
            '$scheme scheme-secret',
            null,
          );
          expect(result, '$scheme $defaultPlaceholder');
        }
      });

      test('preserves diagnostic prose after one authentication token', () {
        const input = 'Bearer auth-secret requestId=visible retry=3';

        final result = RedactionService.redactExportString(input, null);

        expect(result, 'Bearer $defaultPlaceholder requestId=visible retry=3');
        expect(RedactionService.redactExportString(result, null), result);
      });

      test('scrubs a multi-field Digest challenge', () {
        const input =
            'Digest username="alice", realm="private", nonce="secret" retry=3';

        final result = RedactionService.redactExportString(input, null);

        expect(result, isNot(contains('alice')));
        expect(result, isNot(contains('private')));
        expect(result, isNot(contains('secret')));
        expect(result, contains('retry=3'));
      });

      test('scrubs spaced Digest and OAuth authentication parameters', () {
        for (final scheme in const ['Digest', 'OAuth']) {
          final result = RedactionService.redactExportString(
            '$scheme username = "alice", nonce = "SPACED_AUTH_SECRET" retry=3',
            null,
          );

          expect(result, '$scheme $defaultPlaceholder retry=3');
        }
      });

      test('fails closed for unterminated Digest and OAuth quoted values', () {
        for (final scheme in const ['Digest', 'OAuth']) {
          for (final quote in const ['"', "'"]) {
            final result = RedactionService.redactExportString(
              '$scheme username=$quote'
              'UNFINISHED AUTH SECRET WITH SPACE; requestId=42',
              null,
            );

            expect(result, '$scheme $defaultPlaceholder');
            expect(result, isNot(contains('UNFINISHED')));
            expect(result, isNot(contains('AUTH SECRET')));
            expect(result, isNot(contains('requestId')));
          }
        }
      });

      test('scrubs semicolons inside balanced authentication values', () {
        const input = 'Digest opaque="AUTH;SECRET", nonce="N" retry=3';

        final result = RedactionService.redactExportString(input, null);

        expect(result, 'Digest $defaultPlaceholder retry=3');
        expect(result, isNot(contains('AUTH;SECRET')));
        expect(result, isNot(contains('nonce')));
      });

      test('scrubs every field in a bare OAuth parameter list', () {
        const input = 'OAuth oauth_consumer_key="id", '
            'oauth_token="OAUTH_SECRET", oauth_signature="SIGNATURE" retry=3';

        final result = RedactionService.redactExportString(input, null);

        expect(result, 'OAuth $defaultPlaceholder retry=3');
      });

      test('fails closed for unknown authorization header schemes', () {
        const input = 'Authorization: DPoP FUTURE_SCHEME_SECRET requestId=42';

        final result = RedactionService.redactExportString(input, null);

        expect(result, 'Authorization: $defaultPlaceholder');
        expect(result, isNot(contains('FUTURE_SCHEME_SECRET')));
      });

      test('fails closed for proxy authorization assignments', () {
        const input = 'Proxy-Authorization=ApiKey PROXY_SECRET';

        final result = RedactionService.redactExportString(input, null);

        expect(result, 'Proxy-Authorization=$defaultPlaceholder');
      });

      test('scrubs absolute and file URI paths from diagnostic text', () {
        final result = RedactionService.redactExportString(
          'at file:///Users/alice/project/lib/auth.dart:12:3 '
          'from /home/alice/secrets/config.json '
          r'and C:\Users\alice\secrets.txt',
          defaultSensitiveKeys,
        );

        expect(result, isNot(contains('alice')));
        expect(result, isNot(contains('auth.dart')));
        expect(result, isNot(contains('config.json')));
        expect(result, isNot(contains('secrets.txt')));
        expect(result, contains(defaultPlaceholder));
      });

      test('scrubs complete quoted paths containing spaces', () {
        const input =
            '''FileSystemException: path='/Users/alice/My Project/customer-secret.txt' '''
            '''file="file:///home/alice/My Files/token.txt" '''
            r'''windows='C:\Users\Alice Smith\private\secret.txt' safe=visible''';

        final result = RedactionService.redactExportString(
          input,
          defaultSensitiveKeys,
        );

        expect(result, isNot(contains('My Project')));
        expect(result, isNot(contains('customer-secret.txt')));
        expect(result, isNot(contains('My Files')));
        expect(result, isNot(contains('Alice Smith')));
        expect(result, isNot(contains('secret.txt')));
        expect(result, contains('safe=visible'));
      });

      test('scrubs unquoted paths containing spaces and UNC paths', () {
        const input = 'at /Users/Alice Smith/project/customer-secret.dart:12\n'
            r'at \\server\Team Share\private\secret.txt:4';

        final result = RedactionService.redactExportString(input, null);

        expect(
          result,
          'at $defaultPlaceholder\nat $defaultPlaceholder',
        );
        expect(result, isNot(contains('Alice Smith')));
        expect(result, isNot(contains('Team Share')));
        expect(result, isNot(contains('customer-secret.dart')));
        expect(result, isNot(contains('secret.txt')));
      });

      test('scrubs path segments whose names look like prose boundaries', () {
        for (final input in const [
          'at /Users/Alice and Bob/project/customer-secret.dart',
          r'at C:\Users\request failed\private\secret.txt',
          r'at \\server\before and after\private\secret.txt',
        ]) {
          final result = RedactionService.redactExportString(input, null);

          expect(result, 'at $defaultPlaceholder');
          expect(
            RedactionService.redactExportString(result, null),
            result,
          );
        }
      });

      test('preserves prose after an unquoted stack location', () {
        const input =
            'failed at /Users/alice/foo.dart:12:3 because request timed out';

        final result = RedactionService.redactExportString(input, null);

        expect(
          result,
          'failed at $defaultPlaceholder because request timed out',
        );
        expect(
          RedactionService.redactExportString(result, null),
          result,
        );
      });

      test('preserves separators between multiple unquoted paths', () {
        const input =
            'copied from /Users/alice/source.dart:4 and /home/bob/target.dart:8';

        final result = RedactionService.redactExportString(input, null);

        expect(
          result,
          'copied from $defaultPlaceholder and $defaultPlaceholder',
        );
      });

      test('scrubs complete quoted UNC paths containing spaces', () {
        const input =
            r'''path='\\server\Team Share\private\secret.txt' safe=visible''';

        final result = RedactionService.redactExportString(input, null);

        expect(result, "path='$defaultPlaceholder' safe=visible");
        expect(result, isNot(contains('Team Share')));
        expect(result, isNot(contains('secret.txt')));
      });

      test('scrubs file URIs with an authority', () {
        const input =
            "path='file://server/share/Team Secret.txt' safe=visible\n"
            'at file://localhost/C:/Users/Alice Smith/private.txt';

        final result = RedactionService.redactExportString(input, null);

        expect(
          result,
          "path='file://$defaultPlaceholder' safe=visible\n"
          'at file://$defaultPlaceholder',
        );
        expect(result, isNot(contains('server/share')));
        expect(result, isNot(contains('Alice Smith')));
        expect(result, isNot(contains('private.txt')));
      });
    });

    group('redactForExport', () {
      test('never executes caller DTO formatters', () {
        final value = _HostileExportDto();

        final result = RedactionService().redactForExport(value);

        expect(result.toString(), isNot(contains('HOSTILE-EXPORT-DTO-SECRET')));
        expect(value.toJsonCalls, 0);
        expect(value.toStringCalls, 0);
      });

      test('bounds oversized strings with redaction enabled and disabled', () {
        final oversized = 'x' * (4 * 1024 * 1024);

        final masked = RedactionService().redactForExport(oversized)! as String;
        ISpectRedaction.enabled = false;
        final raw = RedactionService().redactForExport(oversized)! as String;

        expect(
          LogExportOutput.utf8Length(masked),
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
        expect(
          LogExportOutput.utf8Length(raw),
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
        expect(raw, endsWith(LogExportOutput.truncatedMarker));
      });

      test('honors the caller resource limits', () {
        final payload = List<String>.filled(30000, 'safe-value').join('|');

        final extended = RedactionService().redactForExport(
          payload,
          resourceLimits: DiagnosticResourceLimits.extended,
        );
        final constrained = RedactionService().redactForExport(
          payload,
          resourceLimits: DiagnosticResourceLimits.constrained,
        );

        expect(extended, payload);
        expect(
          LogExportOutput.utf8Length(constrained! as String),
          lessThanOrEqualTo(
            DiagnosticResourceLimits.constrained.maxCapturedValueBytes,
          ),
        );
        expect(constrained, isNot(payload));
      });

      test('redacts short root credentials without separator characters', () {
        final service = RedactionService();

        expect(
          service.redactForExport('AKIAIOSFODNN7EXAMPLE'),
          isNot('AKIAIOSFODNN7EXAMPLE'),
        );
        expect(
          service.redactForExport('AIzaSyExampleCredential'),
          isNot('AIzaSyExampleCredential'),
        );
      });

      test('applies caller resource limits while hardening headers', () {
        final value = List<String>.filled(30000, 'safe-value').join('|');

        final headers = RedactionService().redactHeaders(
          {'x-debug': value},
          resourceLimits: DiagnosticResourceLimits.extended,
        );

        expect(headers['x-debug'], value);
      });

      test('bounds multi-MiB typed binary under both masking opt-outs', () {
        const byteLength = 4 * 1024 * 1024;
        final bytes = Uint8List(byteLength);

        final binaryOptOut = RedactionService(
          redactBinary: false,
        ).redactForExport({'payload': bytes})! as Map<String, Object?>;
        ISpectRedaction.enabled = false;
        final globalOptOut = RedactionService().redactForExport({
          'payload': bytes.buffer,
        })! as Map<String, Object?>;

        for (final payload in [
          binaryOptOut['payload'],
          globalOptOut['payload'],
        ]) {
          expect(payload, '[binary $byteLength bytes]');
          expect(identical(payload, bytes), isFalse);
          expect(identical(payload, bytes.buffer), isFalse);
        }
      });

      test('scrubs free-form strings recursively after structural redaction',
          () {
        final service = RedactionService(sensitiveKeys: const {'token'});
        final result = service.redactForExport({
          'message': 'GET /profile?token=message-secret',
          'nested': [
            {'token': 'structural-secret'},
            Exception('Bearer exception-secret'),
          ],
        })! as Map<String, Object?>;

        expect(result.toString(), isNot(contains('message-secret')));
        expect(result.toString(), isNot(contains('structural-secret')));
        expect(result.toString(), isNot(contains('exception-secret')));
      });

      test('redacts typed binary before normalizing an outbound payload', () {
        final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

        final result = RedactionService().redactForExport({
          'payload': bytes,
        })! as Map<String, Object?>;
        final payload = result['payload']! as List<Object?>;

        expect(payload, '[binary 64 bytes]'.codeUnits);
        expect(payload, isNot(equals(bytes)));
      });

      test('keeps typed binary atomic when binary masking is disabled', () {
        final bytes = Uint8List.fromList([1, 2, 3]);
        final buffer = Uint8List.fromList([4, 5, 6]).buffer;
        final ordinaryList = <Object?>[7, 8, 9];
        final result = RedactionService(
          redactBinary: false,
        ).redactForExport({
          'diagnosticBytes': bytes,
          'diagnosticBuffer': buffer,
          'ordinaryList': ordinaryList,
        })! as Map<String, Object?>;

        expect(identical(result['diagnosticBytes'], bytes), isTrue);
        expect(identical(result['diagnosticBuffer'], buffer), isTrue);
        expect(result['ordinaryList'], equals(ordinaryList));
        expect(identical(result['ordinaryList'], ordinaryList), isFalse);
      });

      test('global redaction opt-out preserves masking only', () {
        final service = RedactionService(sensitiveKeys: const {'token'});
        ISpectRedaction.enabled = false;
        addTearDown(() => ISpectRedaction.enabled = true);

        final input = {'message': 'GET /profile?token=raw-secret'};
        final result = service.redactForExport(input)! as Map<String, Object?>;

        expect(result, input);
        expect(identical(result, input), isFalse);
      });

      test('redactUrl never formats custom strategy output', () {
        final hostile = _HostileStrategyValue();
        final service = RedactionService(
          strategy: _ReturningStrategy(hostile),
        );

        final output = service.redactUrl(
          'https://example.test/path?token=secret',
        );

        expect(output, isNot(contains('secret')));
        expect(hostile.toStringCalls, 0);
      });

      test('redactUrl rejects oversized custom strategy output', () {
        final service = RedactionService(
          strategy: _ReturningStrategy('x' * (4 * 1024 * 1024)),
        );

        final output = service.redactUrl(
          'https://example.test/path?token=secret',
        );

        expect(
          LogExportOutput.utf8Length(output),
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
        expect(output, isNot(contains('secret')));
      });

      test('scrubs a configured key in the first form field', () {
        final service = RedactionService(sensitiveKeys: const {'tenantSecret'});

        final result =
            service.redactForExport('tenantSecret=SECRET&ok=1').toString();

        expect(result, isNot(contains('SECRET')));
        expect(result, contains('tenantSecret=[REDACTED]'));
        expect(result, contains('ok=1'));
      });

      test('classifies camel-case sensitive assignments in prose', () {
        const input = r'''clientSecret="TOP \"CLIENT SECRET\"" '''
            "customerPassword: 'CUSTOMER,PASSWORD'";

        final result = RedactionService().redactForExport(input).toString();

        expect(result, isNot(contains('CLIENT SECRET')));
        expect(result, isNot(contains('CUSTOMER,PASSWORD')));
      });

      test('classifies quoted camel-case and escaped JSON keys', () {
        const input = r'''
          {"accessToken":"CAMEL_JSON_SECRET",
           "client\u0053ecret":"ESCAPED_JSON_SECRET",
           "safe":"visible"}
        ''';

        final result = RedactionService().redactForExport(input).toString();

        expect(result, isNot(contains('CAMEL_JSON_SECRET')));
        expect(result, isNot(contains('ESCAPED_JSON_SECRET')));
        expect(result, contains('"safe":"visible"'));
        expect(result, contains('"accessToken":"[REDACTED]"'));
      });

      test('classifies multiline quoted JSON assignments', () {
        const input =
            '{"accessToken"\r\n:\n"CAMEL_MULTILINE_SECRET","safe":"visible"}';

        final result = RedactionService().redactForExport(input).toString();

        expect(result, isNot(contains('CAMEL_MULTILINE_SECRET')));
        expect(result, contains('"safe":"visible"'));
        expect(result, contains(defaultPlaceholder));
      });

      test('preserves safe siblings after sensitive JSON containers', () {
        for (final input in const [
          '{"accessToken":{"deep":"OBJECT_SECRET"},"safe":"visible"}',
          '{"accessToken":["LIST_SECRET"],"safe":"visible"}',
        ]) {
          final result = RedactionService().redactForExport(input).toString();
          final decoded = jsonDecode(result) as Map<String, Object?>;

          expect(result, isNot(contains('SECRET')));
          expect(decoded['accessToken'], defaultPlaceholder);
          expect(decoded['safe'], 'visible');
        }
      });

      test('preserves safe siblings after sensitive JSON scalars', () {
        for (final input in const [
          '{"accessToken":true,"safe":"visible"}',
          '{"accessToken":false,"safe":"visible"}',
          '{"accessToken":null,"safe":"visible"}',
          '{"accessToken":42,"safe":"visible"}',
        ]) {
          final result = RedactionService().redactForExport(input).toString();
          final decoded = jsonDecode(result) as Map<String, Object?>;

          expect(decoded['accessToken'], defaultPlaceholder);
          expect(decoded['safe'], 'visible');
        }
      });

      test('fully masks terminal credential segments in structural keys', () {
        final result = RedactionService().redactForExport({
          'auth[token]': 'TOKEN_PREFIX_secret_TOKEN_SUFFIX',
          'user[password]': 'PASSWORD_PREFIX_secret_PASSWORD_SUFFIX',
          'safe': 'visible',
        })! as Map<String, Object?>;

        expect(result['auth[token]'], defaultPlaceholder);
        expect(result['user[password]'], defaultPlaceholder);
        expect(result['safe'], 'visible');
      });

      test('redacts encoded form keys at the start of a body', () {
        for (final input in const [
          'access%5Ftoken=ENCODED_FORM_SECRET&safe=visible',
          '%74oken=SHORT_ENCODED_FORM_SECRET&safe=visible',
          'auth%5Btoken%5D=BRACKET_FORM_SECRET&safe=visible',
        ]) {
          final result = RedactionService().redactForExport(input).toString();

          expect(result, isNot(contains('FORM_SECRET')));
          expect(result, contains('safe=visible'));
          expect(result, contains(defaultPlaceholder));
        }
      });

      test('redacts prefixed bracketed and encoded form assignments', () {
        for (final input in const [
          'payload auth[token]=PREFIXED_BRACKET_SECRET safe=visible',
          'payload user[password]=PREFIXED_PASSWORD_SECRET safe=visible',
          'payload access%5Ftoken=PREFIXED_ENCODED_SECRET safe=visible',
          'payload auth%5Btoken%5D=PREFIXED_FORM_SECRET safe=visible',
          'payload auth[token]: PREFIXED_COLON_SECRET safe: visible',
          'payload 2fa_token=DIGIT_PREFIX_TOKEN_SECRET safe=visible',
          'payload _token=UNDERSCORE_PREFIX_TOKEN_SECRET safe=visible',
          '2fa_token=START_DIGIT_TOKEN_SECRET safe=visible',
          '_token=START_UNDERSCORE_TOKEN_SECRET safe=visible',
        ]) {
          final result = RedactionService().redactForExport(input).toString();

          expect(result, isNot(contains('PREFIXED_')));
          expect(result, contains('safe'));
          expect(result, contains('visible'));
          expect(
            RedactionService().redactForExport(result).toString(),
            result,
          );
        }
      });

      test('redacts single-quoted pseudo-JSON keys and containers', () {
        for (final input in const [
          "payload {'password': 'SINGLE_QUOTED_KEY_SECRET', 'safe': 'visible'}",
          "payload {'accessToken': {'deep': 'PSEUDO_CONTAINER_SECRET'}, 'safe': 'visible'}",
        ]) {
          final result = RedactionService().redactForExport(input).toString();

          expect(result, isNot(contains('SECRET')));
          expect(result, contains("'safe': 'visible'"));
          expect(
            RedactionService().redactForExport(result).toString(),
            result,
          );
        }
      });

      test('applies custom patterns to single-quoted pseudo-JSON keys', () {
        final service = RedactionService(
          sensitiveKeys: const {},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        );
        const input = "payload {'tenantCredential': 'CUSTOM_PSEUDO_SECRET', "
            "'safe': 'visible'}";

        final result = service.redactForExport(input).toString();

        expect(result, isNot(contains('CUSTOM_PSEUDO_SECRET')));
        expect(result, contains("'safe': 'visible'"));
      });

      test('redacts sensitive terminal segments in export assignments', () {
        for (final input in const [
          'payload headers[Authorization]=DPoP BRACKET_AUTHORIZATION_SECRET safe=visible',
          'payload headers.Cookie=COOKIE BRACKET_COOKIE_SECRET safe=visible',
          'payload meta[Set-Cookie]=SET_COOKIE_SECRET safe=visible',
          'payload requestAuthorization=GNAP CAMEL_AUTHORIZATION_SECRET safe=visible',
          'payload responseSetCookie=CAMEL_SET_COOKIE_SECRET safe=visible',
          'payload userUsername=CAMEL_USERNAME_SECRET safe=visible',
        ]) {
          final service = RedactionService();
          final result = service.redactForExport(input).toString();

          expect(result, isNot(contains('SECRET')));
          expect(result, contains('safe=visible'));
          expect(service.redactForExport(result).toString(), result);
        }
      });

      test('static export redaction matches terminal key segments', () {
        const input = 'headers[Authorization]=DPoP STATIC_AUTHORIZATION_SECRET '
            'safe=visible';

        final result = RedactionService.redactExportString(
          input,
          defaultSensitiveKeys,
        );

        expect(result, isNot(contains('STATIC_AUTHORIZATION_SECRET')));
        expect(result, contains('safe=visible'));
      });

      test('classifies custom key-pattern assignments in prose', () {
        final service = RedactionService(
          sensitiveKeys: const {},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        );

        final result = service.redactForExport(
          "tenantCredential='alpha,beta' tenantCredential: \"gamma delta\"",
        );

        expect(result.toString(), isNot(contains('alpha')));
        expect(result.toString(), isNot(contains('beta')));
        expect(result.toString(), isNot(contains('gamma')));
        expect(result.toString(), isNot(contains('delta')));
      });

      test('classifies custom key-pattern assignments in quoted JSON', () {
        final service = RedactionService(
          sensitiveKeys: const {},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        );

        final result = service.redactForExport(
          '{"tenantCredential"\n:\n"CUSTOM_JSON_SECRET","safe":"visible"}',
        );

        expect(result.toString(), isNot(contains('CUSTOM_JSON_SECRET')));
        expect(result.toString(), contains('"safe":"visible"'));
        expect(result.toString(), contains('"tenantCredential"'));
        expect(result.toString(), contains(defaultPlaceholder));
      });

      test('scrubs malformed quotes and multiword assignment values', () {
        final service = RedactionService(
          sensitiveKeys: const {'password', 'client_secret'},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        );
        const input = 'password=TOP SECRET VALUE safe=visible; '
            r'''clientSecret="QUOTED, SECRET; WITH \"ESCAPE\"" next=kept; '''
            'password="UNFINISHED DOUBLE, safe=still-visible; '
            "tenantCredential='UNFINISHED SINGLE; done=yes";

        final result = service.redactForExport(input).toString();

        for (final secret in const [
          'TOP SECRET VALUE',
          'QUOTED',
          'WITH',
          'ESCAPE',
          'UNFINISHED DOUBLE',
          'UNFINISHED SINGLE',
        ]) {
          expect(result, isNot(contains(secret)));
        }
        expect(result, contains('safe=visible'));
        expect(result, contains('next=kept'));
      });

      test('fails closed after delimiters in unmatched quoted assignments', () {
        final service = RedactionService(
          sensitiveKeys: const {'password', 'client_secret'},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        );

        for (final input in const [
          'password="DOUBLE_COMMA_SECRET,LEAK_SUFFIX',
          "clientSecret='SINGLE_SEMICOLON_SECRET;LEAK_SUFFIX",
          'tenantCredential="AMPERSAND_SECRET&LEAK_SUFFIX',
        ]) {
          final result = service.redactForExport(input).toString();

          expect(result, isNot(contains('SECRET')));
          expect(result, isNot(contains('LEAK_SUFFIX')));
          expect(result, contains(defaultPlaceholder));
        }
      });

      test('fails closed after delimiters in unquoted assignment values', () {
        final service = RedactionService();

        for (final input in const [
          'password=COMMA_SECRET,LEAK_SUFFIX',
          'clientSecret=SEMICOLON_SECRET;LEAK_SUFFIX',
          'auth.token=AMPERSAND_SECRET&LEAK_SUFFIX',
        ]) {
          final result = service.redactForExport(input).toString();

          expect(result, isNot(contains('SECRET')));
          expect(result, isNot(contains('LEAK_SUFFIX')));
          expect(result, contains(defaultPlaceholder));
        }
      });

      test('classifies dotted structural and prose keys', () {
        final service = RedactionService();
        final result = service.redactForExport({
          'client.secret': 'CLIENT_DOTTED_SECRET',
          'auth.token': 'AUTH_DOTTED_SECRET',
          'user.password': 'PASSWORD_DOTTED_SECRET',
          'message': 'auth.token=PROSE_DOTTED_SECRET safe=visible',
        });
        final rendered = result.toString();

        expect(rendered, isNot(contains('CLIENT_DOTTED_SECRET')));
        expect(rendered, isNot(contains('AUTH_DOTTED_SECRET')));
        expect(rendered, isNot(contains('PASSWORD_DOTTED_SECRET')));
        expect(rendered, isNot(contains('PROSE_DOTTED_SECRET')));
        expect(rendered, contains('safe=visible'));
      });

      test('redacts encoded relative query keys in free-form text', () {
        final service = RedactionService(
          sensitiveKeys: const {},
          sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        );

        final result = service.redactForExport(
          'GET /callback?%74enantCredential=RELATIVE_ENCODED_SECRET',
        );

        expect(result.toString(), isNot(contains('RELATIVE_ENCODED_SECRET')));
        expect(result.toString(), contains(defaultPlaceholder));
      });

      test('redacts repeatedly encoded keys in free-form relative URLs', () {
        final result = RedactionService().redactForExport(
          'GET /callback?%2574oken=DOUBLE_ENCODED_PROSE_SECRET',
        );

        expect(
          result.toString(),
          isNot(contains('DOUBLE_ENCODED_PROSE_SECRET')),
        );
        expect(result.toString(), contains(defaultPlaceholder));
      });

      test('applies key-pattern redaction inside an embedded URL', () {
        final service = RedactionService();

        final result = service
            .redactForExport(
              'request failed at https://example.test/v1?api_key=SECRET',
            )
            .toString();

        expect(result, isNot(contains('SECRET')));
        expect(result, contains('api_key='));
      });

      test('fails closed for throwing values and map keys', () {
        final service = RedactionService();
        final result = service.redactForExport({
          'value': const _ThrowingExportValue(),
          const _ThrowingExportKey(): 'secret-behind-unknown-key',
        });

        expect(
          result.toString(),
          contains(JsonValueNormalizer.unprintableValue),
        );
        expect(
          result.toString(),
          isNot(contains('secret-behind-unknown-key')),
        );
      });

      test('replaces cycles without throwing or recursing forever', () {
        final cyclic = <String, Object?>{};
        cyclic['self'] = cyclic;

        final result = RedactionService().redactForExport(cyclic);

        expect(
          result,
          {
            'self': {
              JsonValueNormalizer.traversalMarkerKey:
                  JsonValueNormalizer.circularReference,
            },
          },
        );
      });

      test('bounds lazy unbounded iterables', () {
        final result = RedactionService()
            .redactForExport(_UnboundedExportIterable())! as List<Object?>;

        expect(
          result.last,
          JsonValueNormalizer.maxCollectionItemsReached,
        );
        expect(
          result.length,
          JsonValueNormalizer.defaultMaxCollectionItems + 1,
        );
      });

      test('fails closed when a custom strategy throws', () {
        final service = RedactionService(
          strategy: const _ThrowingStrategy(),
        );

        expect(
          service.redactForExport({'safe': 'value'}),
          defaultPlaceholder,
        );
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

      test('redacts URLs whose paths contain delimiters', () {
        for (final input in const [
          'request https://api.test/a,b?token=COMMA_PATH_SECRET done',
          'request https://api.test/a(b)?token=PAREN_PATH_SECRET done',
        ]) {
          final result = RedactionService().redactUrlsInText(input);

          expect(result, isNot(contains('PATH_SECRET')));
          expect(Uri.decodeFull(result), contains(defaultPlaceholder));
          expect(result, endsWith(' done'));
        }
      });

      test('keeps trailing prose punctuation outside the redacted URL', () {
        const input =
            'failed (https://api.test/a(b)?token=PUNCTUATION_SECRET).';

        final result = RedactionService().redactUrlsInText(input);

        expect(result, isNot(contains('PUNCTUATION_SECRET')));
        expect(result, endsWith(').'));
      });

      test('redacts protocol-relative URLs embedded in diagnostic text', () {
        const input =
            'request //alice:hunter2@api.test/path?token=PROTOCOL_SECRET '
            'safe=visible';

        for (final result in [
          RedactionService().redactForExport(input).toString(),
          RedactionService.redactExportString(
            input,
            defaultSensitiveKeys,
          ),
        ]) {
          expect(result, isNot(contains('alice:hunter2')));
          expect(result, isNot(contains('hunter2')));
          expect(result, isNot(contains('PROTOCOL_SECRET')));
          expect(result, contains('safe=visible'));
        }
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

      test('scrubs names and arbitrary values on the stats path', () {
        const rawName = 'sk-STATSHEADERNAMESECRET123456';
        const valueSecret = 'STATS-ARBITRARY-HEADER-VALUE';
        final service = RedactionService();

        final result = service.redactHeadersWithStats({
          rawName: 'password=$valueSecret',
        });

        expect(result.headers.keys, contains(defaultPlaceholder));
        expect(result.headers.toString(), isNot(contains(rawName)));
        expect(result.headers.toString(), isNot(contains(valueSecret)));
        expect(result.stats.patternBased, greaterThan(0));
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

      test('detects GitHub fine-grained PATs (github_pat_)', () {
        final service = RedactionService();
        final result = service.redactWithStats({
          'data': 'github_pat_abcdefghijklmnopqrstuvwxyz0123456789',
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
