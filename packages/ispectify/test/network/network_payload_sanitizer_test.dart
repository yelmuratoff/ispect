import 'dart:collection';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/bounded_json_decoder.dart';
import 'package:test/test.dart';

final class _HostileDto {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object toJson() {
    toJsonCalls++;
    throw StateError('toJson must not run');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('toString must not run');
  }
}

final class _HostileKey {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('key toString must not run');
  }
}

final class _GuardedUnboundedIterable extends Iterable<Object?> {
  @override
  Iterator<Object?> get iterator => _GuardedUnboundedIterator();
}

final class _GuardedUnboundedIterator implements Iterator<Object?> {
  int _moves = 0;

  @override
  Object? get current => 1;

  @override
  bool moveNext() {
    _moves++;
    if (_moves > JsonValueNormalizer.defaultMaxCollectionItems + 1) {
      throw StateError('unbounded iterable was consumed without a limit');
    }
    return true;
  }
}

final class _ThrowingIterable extends Iterable<Object?> {
  @override
  Iterator<Object?> get iterator => _ThrowingIterator();
}

final class _ThrowingIterator implements Iterator<Object?> {
  @override
  Object? get current => throw StateError('current failed');

  @override
  bool moveNext() => throw StateError('moveNext failed');
}

final class _NullExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      null;
}

final class _ThrowingExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      throw StateError('custom redactor failed');
}

final class _CyclicExportRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final result = <String, Object?>{};
    result['self'] = result;
    return result;
  }
}

final class _ThrowOnMapIteration extends MapBase<Object?, Object?> {
  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(Object? key, Object? value) =>
      throw UnsupportedError('immutable');

  @override
  void clear() => throw UnsupportedError('immutable');

  @override
  Iterable<Object?> get keys => throw StateError('keys unavailable');

  @override
  Object? remove(Object? key) => throw UnsupportedError('immutable');
}

void main() {
  group('NetworkPayloadSanitizer.toStringKeyMap', () {
    test('replaces unknown values without executing caller methods', () {
      final value = _HostileDto();

      final result = NetworkPayloadSanitizer.toStringKeyMap(
        <Object?, Object?>{'diagnostic': value},
      );

      expect(result['diagnostic'], isA<String>());
      expect(value.toJsonCalls, 0);
      expect(value.toStringCalls, 0);
    });

    test('does not stringify non-string keys', () {
      final hostileKey = _HostileKey();

      final result = NetworkPayloadSanitizer.toStringKeyMap(
        <Object?, Object?>{
          hostileKey: 'untrusted',
          'requestId': 'trusted',
        },
      );

      expect(result, containsPair('requestId', 'trusted'));
      expect(
        result,
        containsPair(
          JsonValueNormalizer.traversalMarkerKey,
          JsonValueNormalizer.unprintableValue,
        ),
      );
      expect(hostileKey.toStringCalls, 0);
    });

    test('bounds wide maps and marks truncation', () {
      final input = <Object?, Object?>{
        for (var index = 0;
            index < JsonValueNormalizer.defaultMaxCollectionItems + 1;
            index++)
          index: index,
      };

      final result = NetworkPayloadSanitizer.toStringKeyMap(input);

      expect(
        result,
        containsPair(
          JsonValueNormalizer.traversalMarkerKey,
          JsonValueNormalizer.maxCollectionItemsReached,
        ),
      );
    });

    test('fails closed when a map cannot be traversed', () {
      final result = NetworkPayloadSanitizer.toStringKeyMap(
        _ThrowOnMapIteration(),
      );

      expect(result.values, contains(JsonValueNormalizer.unprintableValue));
    });
  });

  group('NetworkPayloadSanitizer.decodeJsonGracefully', () {
    test('decodes ordinary JSON containers and scalar values', () {
      expect(
        NetworkPayloadSanitizer.decodeJsonGracefully(
          '{"locale":"en_US","items":[1,true,null]}',
        ),
        <String, dynamic>{
          'locale': 'en_US',
          'items': <Object?>[1, true, null],
        },
      );
      expect(NetworkPayloadSanitizer.decodeJsonGracefully('42'), 42);
      expect(NetworkPayloadSanitizer.decodeJsonGracefully('true'), isTrue);
      expect(NetworkPayloadSanitizer.decodeJsonGracefully('null'), isNull);
    });

    test('preserves ordinary non-JSON text and non-string values', () {
      const text = '404 response was not JSON';
      const map = <String, dynamic>{'already': 'decoded'};

      expect(NetworkPayloadSanitizer.decodeJsonGracefully(text), text);
      final decodedMap = NetworkPayloadSanitizer.decodeJsonGracefully(map);
      expect(decodedMap, map);
      expect(identical(decodedMap, map), isFalse);
      expect(NetworkPayloadSanitizer.decodeJsonGracefully(''), isNull);
    });

    test('preserves malformed structured JSON for compatibility callers', () {
      const source = '{"token":"MALFORMED-REMOTE-SECRET",}';

      expect(
        NetworkPayloadSanitizer.decodeJsonGracefully(source),
        source,
      );
    });

    test('bounds JSON beyond the character budget without parsing it', () {
      final json = '"${List.filled(
        BoundedJsonDecoder.defaultMaxCharacters,
        'x',
      ).join()}"';

      final result =
          NetworkPayloadSanitizer.decodeJsonGracefully(json)! as String;
      expect(
        LogExportOutput.utf8Length(result),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(result, contains(LogExportOutput.truncatedMarker));
    });

    test('bounds JSON beyond the encoded-byte budget without parsing it', () {
      final json = '"${List.filled(
        BoundedJsonDecoder.defaultMaxEncodedBytes ~/ 3,
        '界',
      ).join()}"';

      final result =
          NetworkPayloadSanitizer.decodeJsonGracefully(json)! as String;
      expect(
        LogExportOutput.utf8Length(result),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
      expect(result, contains(LogExportOutput.truncatedMarker));
    });

    test('bounds a huge non-JSON response while retaining an opt-out prefix',
        () {
      final text = 'visible-${List.filled(
        LogExportOutput.maxRecordBytes,
        'x',
      ).join()}';

      final result =
          NetworkPayloadSanitizer.decodeJsonGracefully(text)! as String;

      expect(result, startsWith('visible-'));
      expect(result, contains(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(result),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('preserves deeply nested JSON without decoding it', () {
      final json = '${List.filled(
        BoundedJsonDecoder.defaultMaxDepth + 1,
        '[',
      ).join()}0${List.filled(
        BoundedJsonDecoder.defaultMaxDepth + 1,
        ']',
      ).join()}';

      expect(
        NetworkPayloadSanitizer.decodeJsonGracefully(json),
        json,
      );
    });

    test('preserves a collection wider than the per-container budget', () {
      final json = '[${List.filled(
        BoundedJsonDecoder.defaultMaxCollectionItems + 1,
        '0',
      ).join(',')}]';

      expect(
        NetworkPayloadSanitizer.decodeJsonGracefully(json),
        json,
      );
    });

    test('preserves a tree beyond the total node budget', () {
      final child = '[${List.filled(600, '0').join(',')}]';
      final json = '[${List.filled(20, child).join(',')}]';

      expect(
        NetworkPayloadSanitizer.decodeJsonGracefully(json),
        json,
      );
    });
  });

  group('NetworkPayloadSanitizer.headersMap', () {
    setUp(ISpectRedaction.reset);
    tearDown(ISpectRedaction.reset);

    test('scrubs data embedded in header names and arbitrary values', () {
      const rawName = 'sk-HEADERNAMESECRET123456';
      const valueSecret = 'HEADER-VALUE-SECRET';
      const cookieNameSecret = 'sk-COOKIE-NAME-SECRET-123456';
      const listSecret = 'HEADER-LIST-SECRET';
      final sanitizer = NetworkPayloadSanitizer(RedactionService());

      final result = sanitizer.headersMap(
        const <String, Object?>{
          rawName: 'password=$valueSecret',
          'Cookie': '$cookieNameSecret=value',
          'X-List': <String>[
            'token=$listSecret',
            'visible',
          ],
        },
        enableRedaction: true,
      );

      final serialized = result.toString();
      expect(result.keys, contains(defaultPlaceholder));
      expect(serialized, isNot(contains(rawName)));
      expect(serialized, isNot(contains(valueSecret)));
      expect(serialized, isNot(contains(cookieNameSecret)));
      expect(serialized, isNot(contains(listSecret)));
      expect(result['X-List'], isA<List<Object?>>());
      expect(result['X-List'], contains('visible'));
    });

    test('uses an explicit service for PII stored in a header name', () {
      const rawName = 'email=ada@example.test';
      const valueSecret = 'EXPLICIT-HEADER-VALUE';
      final sanitizer = NetworkPayloadSanitizer(
        RedactionService(
          sensitiveKeys: const {'email', 'tenantSecret'},
          sensitiveKeyPatterns: const <RegExp>[],
          placeholder: '<EXPLICIT_HEADER>',
        ),
      );

      final result = sanitizer.headersMap(
        const <String, Object?>{
          rawName: 'tenantSecret=$valueSecret',
        },
        enableRedaction: true,
      );

      expect(result, contains('<EXPLICIT_HEADER>'));
      expect(result.toString(), isNot(contains('ada@example.test')));
      expect(result.toString(), isNot(contains(valueSecret)));
    });

    test('keeps colliding redacted names deterministic', () {
      final sanitizer = NetworkPayloadSanitizer(
        RedactionService(placeholder: '<HEADER_NAME>'),
      );

      final result = sanitizer.headersMap(
        const <String, Object?>{
          'sk-FIRSTHEADERNAMESECRET1234': 'first',
          'sk-SECONDHEADERNAMESECRET123': 'second',
        },
        enableRedaction: true,
      );

      expect(result, const <String, Object?>{'<HEADER_NAME>': 'first'});
    });

    test('prefers an unchanged name over a colliding redacted name', () {
      final sanitizer = NetworkPayloadSanitizer(
        RedactionService(placeholder: '<HEADER_NAME>'),
      );

      final result = sanitizer.headersMap(
        const <String, Object?>{
          'sk-COLLIDINGHEADERNAMESECRET': 'redacted-name',
          '<HEADER_NAME>': 'unchanged-name',
        },
        enableRedaction: true,
      );

      expect(
        result,
        const <String, Object?>{'<HEADER_NAME>': 'unchanged-name'},
      );
    });

    test('fails closed when export scrubbing returns null', () {
      const rawName = 'sk-NULLREDACTORHEADERSECRET';
      const rawValue = 'password=NULL-REDACTOR-VALUE';
      final sanitizer = NetworkPayloadSanitizer(_NullExportRedactor());

      final result = sanitizer.headersMap(
        const <String, Object?>{rawName: rawValue},
        enableRedaction: true,
      );

      expect(
        result,
        const <String, Object?>{
          defaultPlaceholder: defaultPlaceholder,
        },
      );
      expect(result.toString(), isNot(contains(rawName)));
      expect(result.toString(), isNot(contains(rawValue)));
    });

    test('preserves raw names and values only for an explicit opt-out', () {
      const rawName = 'email=raw.person@example.test';
      const rawValue = 'password=RAW-HEADER-VALUE';
      final sanitizer = NetworkPayloadSanitizer(RedactionService());

      final result = sanitizer.headersMap(
        const <String, Object?>{rawName: rawValue},
        enableRedaction: false,
      );

      expect(result, const <String, Object?>{rawName: rawValue});
    });
  });

  group('NetworkPayloadSanitizer.body', () {
    late NetworkPayloadSanitizer sanitizer;

    setUp(() {
      sanitizer = NetworkPayloadSanitizer(RedactionService());
    });

    test('redacts sensitive keys in a JSON-encoded string', () {
      const secret = 'JSON-STRING-SECRET';

      final result = sanitizer.body(
        '{"locale":"en_US","password":"$secret"}',
        enableRedaction: true,
      );

      expect(result, isA<String>());
      expect(result, contains('en_US'));
      expect(result, isNot(contains(secret)));
    });

    test('preserves a JSON-encoded string when redaction is disabled', () {
      const body = '{"password":"RAW-SECRET"}';

      expect(
        sanitizer.body(body, enableRedaction: false),
        body,
      );
    });

    test('preserves non-JSON text while redaction is enabled', () {
      const body = 'plain request body';

      expect(
        sanitizer.body(body, enableRedaction: true),
        body,
      );
    });

    test('preserves prose wrapped in multiple quoted spans', () {
      const body = '"hello" said "world"';

      expect(
        sanitizer.body(body, enableRedaction: true),
        body,
      );
    });

    test('redacts an encoded form key at the start of a body', () {
      final result = sanitizer.body(
        'access%5Ftoken=ENCODED_FORM_SECRET&safe=visible',
        enableRedaction: true,
      );

      expect(result, isA<String>());
      expect(result, isNot(contains('ENCODED_FORM_SECRET')));
      expect(result, contains('safe=visible'));
      expect(result, contains(defaultPlaceholder));
    });

    test('scrubs malformed JSON with configured sensitive keys', () {
      const secret = 'MALFORMED-CUSTOM-SECRET';
      final customSanitizer = NetworkPayloadSanitizer(
        RedactionService(sensitiveKeys: {'tenantSecret'}),
      );

      final result = customSanitizer.body(
        '{"tenantSecret":"$secret",}',
        enableRedaction: true,
      );

      expect(result, redactionFailedPlaceholder);
      expect(result.toString(), isNot(contains(secret)));
    });

    test('preserves malformed JSON when redaction is disabled', () {
      const body = '{"tenantSecret":"RAW-MALFORMED-SECRET",}';

      expect(
        sanitizer.body(body, enableRedaction: false),
        body,
      );
    });

    test('bounds oversized JSON with a visible opt-out prefix', () {
      final body = '{"password":"${List.filled(
        BoundedJsonDecoder.defaultMaxCharacters,
        'x',
      ).join()}"}';

      final result = sanitizer.body(body, enableRedaction: false)! as String;

      expect(result, startsWith('{"password":"'));
      expect(result, contains(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(result),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('fails closed before scanning a huge non-JSON body', () {
      final body = 'visible-${List.filled(
        LogExportOutput.maxRecordBytes,
        'x',
      ).join()}';

      final result = sanitizer.body(body, enableRedaction: true);

      expect(result, LogExportOutput.truncatedMarker);
    });

    test('fails closed for hostile remote JSON before redaction', () {
      const secret = 'DEEP-REMOTE-SECRET';
      final body = '${List.filled(
        BoundedJsonDecoder.defaultMaxDepth + 1,
        '[',
      ).join()}"$secret"${List.filled(
        BoundedJsonDecoder.defaultMaxDepth + 1,
        ']',
      ).join()}';

      final result = sanitizer.body(body, enableRedaction: true);

      expect(result, redactionFailedPlaceholder);
      expect(result.toString(), isNot(contains(secret)));
    });

    test('scrubs a configured key in a form-encoded body', () {
      const secret = 'FORM-CUSTOM-SECRET';
      final customSanitizer = NetworkPayloadSanitizer(
        RedactionService(sensitiveKeys: {'tenantSecret'}),
      );

      final result = customSanitizer.body(
        'tenantSecret=$secret&locale=en_US',
        enableRedaction: true,
      );

      expect(result, isA<String>());
      expect(result, contains('locale=en_US'));
      expect(result, isNot(contains(secret)));
    });

    test('preserves a form-encoded body when redaction is disabled', () {
      const body = 'tenantSecret=RAW-FORM-SECRET&locale=en_US';

      expect(
        sanitizer.body(body, enableRedaction: false),
        body,
      );
    });

    test('fails closed when a configured redactor returns null', () {
      final nullSanitizer = NetworkPayloadSanitizer(_NullExportRedactor());

      expect(
        nullSanitizer.body(
          '{"password":"NEVER-RETAIN"}',
          enableRedaction: true,
        ),
        redactionFailedPlaceholder,
      );
    });

    test('fails closed when a configured redactor throws', () {
      final throwingSanitizer =
          NetworkPayloadSanitizer(_ThrowingExportRedactor());

      expect(
        throwingSanitizer.body(
          '{"password":"NEVER-RETAIN"}',
          enableRedaction: true,
        ),
        redactionFailedPlaceholder,
      );
    });

    test('bounds cyclic output from a configured redactor', () {
      final cyclicSanitizer = NetworkPayloadSanitizer(_CyclicExportRedactor());

      final result = cyclicSanitizer.body(
        '{"password":"NEVER-RETAIN"}',
        enableRedaction: true,
      );

      expect(result, contains(JsonValueNormalizer.circularReference));
      expect(result, isNot(contains('NEVER-RETAIN')));
    });

    test('never executes DTO conversion before or during redaction', () {
      final hostile = _HostileDto();

      final result = sanitizer.body(
        hostile,
        enableRedaction: true,
        normalizer: NetworkPayloadSanitizer.encodeJsonGracefully,
      );

      expect(result, isA<String>());
      expect(hostile.toJsonCalls, 0);
      expect(hostile.toStringCalls, 0);
    });
  });

  group('NetworkPayloadSanitizer.encodeJsonGracefully', () {
    test('snapshots ordinary JSON values without changing their shape', () {
      const map = <String, dynamic>{'k': 'v'};
      const list = <int>[1, 2, 3];

      expect(NetworkPayloadSanitizer.encodeJsonGracefully(null), isNull);
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(map), map);
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(list), list);
      expect(NetworkPayloadSanitizer.encodeJsonGracefully('s'), 's');
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(42), 42);
      expect(NetworkPayloadSanitizer.encodeJsonGracefully(true), true);
      expect(
        identical(
          NetworkPayloadSanitizer.encodeJsonGracefully(map),
          map,
        ),
        isFalse,
      );
    });

    test('snapshots nested pure-JSON structures', () {
      final map = <String, dynamic>{
        'outer': <String, dynamic>{
          'inner': <Object?>[
            1,
            'two',
            null,
            <String, dynamic>{'deep': true},
          ],
        },
      };
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        map,
      );
      expect(encoded, map);
      expect(identical(encoded, map), isFalse);
    });

    test('uses descriptors without invoking DTO methods', () {
      final topLevel = _HostileDto();
      final nested = _HostileDto();
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        <String, dynamic>{
          'provider': 'APPLE',
          'profile': nested,
        },
      )! as Map<String, Object?>;
      final topLevelResult =
          NetworkPayloadSanitizer.encodeJsonGracefully(topLevel);

      expect(encoded['provider'], 'APPLE');
      expect(encoded['profile'], isA<String>());
      expect(topLevelResult, isA<String>());
      expect(nested.toJsonCalls, 0);
      expect(nested.toStringCalls, 0);
      expect(topLevel.toJsonCalls, 0);
      expect(topLevel.toStringCalls, 0);
    });

    test('does not stringify non-string keys', () {
      final key = _HostileKey();
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        <Object, Object?>{key: 'value'},
      )! as Map<String, Object?>;

      expect(
        encoded,
        containsPair(
          JsonValueNormalizer.traversalMarkerKey,
          JsonValueNormalizer.unprintableValue,
        ),
      );
      expect(key.toStringCalls, 0);
    });

    test('preserves bounded TypedData and drops oversized binary', () {
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(bytes),
        same(bytes),
      );

      final oversized = Uint8List(
        LogExportOutput.maxPreparedValueBytes + 1,
      );
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(oversized),
        binaryPlaceholder(oversized.lengthInBytes),
      );
    });

    test('survives a cyclic map without infinite recursion', () {
      final cyclic = <String, dynamic>{'safe': true};
      cyclic['self'] = cyclic;

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(cyclic)!
          as Map<String, dynamic>;

      expect(encoded['safe'], isTrue);
      expect(
        encoded.toString(),
        contains(JsonValueNormalizer.circularReference),
      );
    });

    test('fails closed for values beyond the depth cap', () {
      Object nested = 'deep';
      for (var i = 0; i < 80; i++) {
        nested = <String, dynamic>{'level': nested};
      }

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(nested);
      expect(encoded.toString(), contains(JsonValueNormalizer.maxDepthReached));
    });

    test('bounds unbounded iterables and marks truncation', () {
      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(
        _GuardedUnboundedIterable(),
      )! as List<Object?>;

      expect(
        encoded,
        hasLength(JsonValueNormalizer.defaultMaxCollectionItems + 1),
      );
      expect(
        encoded.last,
        JsonValueNormalizer.maxCollectionItemsReached,
      );
    });

    test('fails closed when an iterable iterator throws', () {
      expect(
        NetworkPayloadSanitizer.encodeJsonGracefully(_ThrowingIterable()),
        <Object?>[JsonValueNormalizer.unprintableValue],
      );
    });

    test('encodes cyclic iterables without recursing forever', () {
      final cyclic = <Object?>['safe'];
      cyclic.add(cyclic);

      final encoded = NetworkPayloadSanitizer.encodeJsonGracefully(cyclic)!
          as List<Object?>;

      expect(encoded.first, 'safe');
      expect(
        encoded.last.toString(),
        contains(JsonValueNormalizer.circularReference),
      );
    });
  });
}
