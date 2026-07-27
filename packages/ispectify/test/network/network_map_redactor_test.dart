import 'dart:collection';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/bounded_json_decoder.dart';
import 'package:test/test.dart';

final class _NullMapRedactor extends RedactionService {
  @override
  Object? redact(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      null;
}

final class _ThrowingMapRedactor extends RedactionService {
  @override
  Object? redact(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      throw StateError('custom redactor failed');
}

final class _NullExportMapRedactor extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      null;
}

final class _ThrowingHeaderRedactor extends RedactionService {
  @override
  Map<String, Object?> redactHeaders(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      throw StateError('custom header redactor failed');
}

final class _ThrowOnIterationMap extends MapBase<Object?, Object?> {
  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(Object? key, Object? value) =>
      throw UnsupportedError('immutable');

  @override
  void clear() => throw UnsupportedError('immutable');

  @override
  Iterable<Object?> get keys => throw StateError('raw map was traversed');

  @override
  Object? remove(Object? key) => throw UnsupportedError('immutable');
}

final class _CollidingRequestIdKey {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    return NetworkJsonKeys.ispectRequestId;
  }
}

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

final class _HostileException implements Exception {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('exception toString must not run');
  }
}

final class _HostileError extends Error {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('error toString must not run');
  }
}

final class _HostileStackTrace implements StackTrace {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('stack toString must not run');
  }
}

void main() {
  late RedactionService redactor;

  setUp(() {
    ISpectRedaction.enabled = true;
    redactor = RedactionService();
  });

  tearDown(() {
    ISpectRedaction.enabled = true;
  });

  group('NetworkMapRedactor', () {
    group('redactUrl', () {
      test('redacts URL with query parameters', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.url: 'https://api.example.com/users?token=secret123',
        };

        NetworkMapRedactor.redactUrl(map, redactor);

        final url = map[NetworkJsonKeys.url] as String;
        expect(url, isNot(contains('secret123')));
      });

      test('no-op when URL is null', () {
        final map = <String, dynamic>{NetworkJsonKeys.url: null};

        NetworkMapRedactor.redactUrl(map, redactor);

        expect(map[NetworkJsonKeys.url], isNull);
      });

      test('no-op when key is absent', () {
        final map = <String, dynamic>{'other': 'value'};

        NetworkMapRedactor.redactUrl(map, redactor);

        expect(map, {'other': 'value'});
      });

      test('supports custom key', () {
        final map = <String, dynamic>{
          'custom-url': 'https://api.example.com/users?token=secret123',
        };

        NetworkMapRedactor.redactUrl(map, redactor, key: 'custom-url');

        final url = map['custom-url'] as String;
        expect(url, isNot(contains('secret123')));
      });

      test('fails closed before scanning an oversized URL', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.url:
              'https://api.example.com?visible=yes&pad=${List.filled(
            LogExportOutput.maxRecordBytes,
            'x',
          ).join()}',
        };

        NetworkMapRedactor.redactUrl(map, redactor);

        expect(
          map[NetworkJsonKeys.url],
          LogExportOutput.truncatedMarker,
        );
      });

      test('retains a bounded URL prefix for the explicit global opt-out', () {
        ISpectRedaction.enabled = false;
        final map = <String, dynamic>{
          NetworkJsonKeys.url:
              'https://api.example.com?debug=visible&pad=${List.filled(
            LogExportOutput.maxRecordBytes,
            'x',
          ).join()}',
        };

        NetworkMapRedactor.redactUrl(map, redactor);

        final url = map[NetworkJsonKeys.url] as String;
        expect(url, startsWith('https://api.example.com?debug=visible'));
        expect(url, contains(LogExportOutput.truncatedMarker));
        expect(
          LogExportOutput.utf8Length(url),
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
      });
    });

    group('redactHeaders', () {
      test('redacts sensitive header values', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: <String, dynamic>{
            'authorization': 'Bearer secret-token-123',
            'content-type': 'application/json',
          },
        };

        NetworkMapRedactor.redactHeaders(map, redactor);

        final headers = map[NetworkJsonKeys.headers] as Map<String, dynamic>;
        expect(headers['authorization'], isNot('Bearer secret-token-123'));
        expect(headers['content-type'], 'application/json');
      });

      test('records only the final safe header name in provenance', () {
        const rawName = 'tenantSecret=RAW-PROVENANCE-HEADER-NAME';
        const safeName = '<SAFE_HEADER_NAME>';
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: const <String, Object?>{
            rawName: 'visible',
          },
        };

        NetworkMapRedactor.redactHeaders(
          map,
          RedactionService(
            sensitiveKeys: const {'tenantSecret'},
            sensitiveKeyPatterns: const <RegExp>[],
            placeholder: '<SAFE_HEADER_NAME>',
          ),
        );

        final headers = map[NetworkJsonKeys.headers] as Map<String, dynamic>;
        final provenance =
            map[NetworkJsonKeys.redactionProvenance] as Map<String, dynamic>;
        expect(headers, const <String, Object?>{safeName: 'visible'});
        expect(
          provenance[NetworkJsonKeys.redactedHeaderKeys],
          const <String>[safeName],
        );
        expect(map.toString(), isNot(contains(rawName)));
        expect(
          map.toString(),
          isNot(contains('RAW-PROVENANCE-HEADER-NAME')),
        );
      });

      test('returns redacted headers map', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: <String, dynamic>{
            'authorization': 'Bearer token',
          },
        };

        final result = NetworkMapRedactor.redactHeaders(map, redactor);

        expect(result, isNotNull);
        expect(result, isA<Map<String, dynamic>>());
      });

      test('returns null when headers absent', () {
        final map = <String, dynamic>{};

        final result = NetworkMapRedactor.redactHeaders(map, redactor);

        expect(result, isNull);
      });

      test('handles Map<String, String> input', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: <String, String>{
            'authorization': 'Bearer token',
          },
        };

        final result = NetworkMapRedactor.redactHeaders(map, redactor);

        expect(result, isNotNull);
      });

      test('omits headers when a custom redactor throws', () {
        const secret = 'THROWING-HEADER-SECRET';
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: <String, dynamic>{
            'authorization': secret,
          },
        };

        final result = NetworkMapRedactor.redactHeaders(
          map,
          _ThrowingHeaderRedactor(),
        );

        expect(result, <String, dynamic>{});
        expect(map.toString(), isNot(contains(secret)));
      });

      test('bounds headers before redaction and never converts hostile values',
          () {
        final key = _CollidingRequestIdKey();
        final value = _HostileDto();
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: <Object?, Object?>{
            key: 'untrusted',
            'x-hostile': value,
            'x-huge': List.filled(
              LogExportOutput.maxRecordBytes,
              'x',
            ).join(),
          },
        };

        final result = NetworkMapRedactor.redactHeaders(map, redactor)!;

        expect(key.toStringCalls, 0);
        expect(value.toJsonCalls, 0);
        expect(value.toStringCalls, 0);
        expect(
          result['x-huge'],
          LogExportOutput.truncatedMarker,
        );
        expect(
          result,
          containsPair(
            JsonValueNormalizer.traversalMarkerKey,
            JsonValueNormalizer.unprintableValue,
          ),
        );
      });

      test('retains bounded header prefixes for the explicit global opt-out',
          () {
        ISpectRedaction.enabled = false;
        final map = <String, dynamic>{
          NetworkJsonKeys.headers: <String, Object?>{
            'x-debug': 'visible-${List.filled(
              LogExportOutput.maxRecordBytes,
              'x',
            ).join()}',
          },
        };

        final result = NetworkMapRedactor.redactHeaders(map, redactor)!;
        final value = result['x-debug'] as String;

        expect(value, startsWith('visible-'));
        expect(value, contains(LogExportOutput.truncatedMarker));
        expect(
          LogExportOutput.utf8Length(value),
          lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
        );
      });
    });

    group('redactData', () {
      test('redacts map body with sensitive keys', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.data: <String, dynamic>{
            'username': 'john',
            'password': 'secret',
          },
        };

        NetworkMapRedactor.redactData(map, redactor);

        final data = map[NetworkJsonKeys.data];
        expect(data, isA<Map<dynamic, dynamic>>());
        final dataMap = data as Map<dynamic, dynamic>;
        expect(dataMap['password'], isNot('secret'));
      });

      test('no-op when key is absent', () {
        final map = <String, dynamic>{'other': 'value'};

        NetworkMapRedactor.redactData(map, redactor);

        expect(map, {'other': 'value'});
      });

      test('preserves null value', () {
        final map = <String, dynamic>{NetworkJsonKeys.data: null};

        NetworkMapRedactor.redactData(map, redactor);

        expect(map[NetworkJsonKeys.data], isNull);
      });

      test('supports custom key', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.body: <String, dynamic>{
            'password': 'secret',
          },
        };

        NetworkMapRedactor.redactData(
          map,
          redactor,
          key: NetworkJsonKeys.body,
        );

        final body = map[NetworkJsonKeys.body] as Map<dynamic, dynamic>;
        expect(body['password'], isNot('secret'));
      });

      test('redacts sensitive keys in a JSON-encoded string', () {
        const secret = 'JSON-BODY-SECRET';
        final map = <String, dynamic>{
          NetworkJsonKeys.data: '{"password":"$secret","safe":"value"}',
        };

        NetworkMapRedactor.redactData(map, redactor);

        final data = map[NetworkJsonKeys.data];
        expect(data, isA<String>());
        expect(data, contains('value'));
        expect(data, isNot(contains(secret)));
      });

      test('fails closed for deeply nested captured JSON', () {
        const secret = 'CAPTURED-DEEP-SECRET';
        final body = '${List.filled(
          BoundedJsonDecoder.defaultMaxDepth + 1,
          '[',
        ).join()}"$secret"${List.filled(
          BoundedJsonDecoder.defaultMaxDepth + 1,
          ']',
        ).join()}';
        final map = <String, dynamic>{NetworkJsonKeys.data: body};

        NetworkMapRedactor.redactData(map, redactor);

        expect(map[NetworkJsonKeys.data], redactionFailedPlaceholder);
        expect(map[NetworkJsonKeys.data].toString(), isNot(contains(secret)));
      });

      test('bounds nested data before redaction without executing DTO methods',
          () {
        final hostile = _HostileDto();
        final map = <String, dynamic>{
          NetworkJsonKeys.data: <String, Object?>{
            'safe': 'visible',
            'nested': <String, Object?>{
              'huge': List.filled(
                LogExportOutput.maxRecordBytes,
                'x',
              ).join(),
              'dto': hostile,
            },
          },
        };

        NetworkMapRedactor.redactData(map, redactor);

        final data = map[NetworkJsonKeys.data] as Map<String, Object?>;
        final nested = data['nested']! as Map<String, Object?>;
        expect(nested['huge'], LogExportOutput.truncatedMarker);
        expect(nested['dto'], isA<String>());
        expect(hostile.toJsonCalls, 0);
        expect(hostile.toStringCalls, 0);
      });

      test('keeps a bounded body prefix for the explicit global opt-out', () {
        ISpectRedaction.enabled = false;
        final map = <String, dynamic>{
          NetworkJsonKeys.data: 'visible-${List.filled(
            LogExportOutput.maxRecordBytes,
            'x',
          ).join()}',
        };

        NetworkMapRedactor.redactData(map, redactor);

        final body = map[NetworkJsonKeys.data] as String;
        expect(body, startsWith('visible-'));
        expect(body, contains(LogExportOutput.truncatedMarker));
      });
    });

    group('redactMapField', () {
      test('redacts map field values', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.extra: <String, dynamic>{
            'api_key': 'secret-key-123',
          },
        };

        NetworkMapRedactor.redactMapField(
          map,
          redactor,
          key: NetworkJsonKeys.extra,
        );

        final extra = map[NetworkJsonKeys.extra];
        expect(extra, isA<Map<dynamic, dynamic>>());
      });

      test('preserves specified keys after redaction', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.extra: <String, dynamic>{
            NetworkJsonKeys.ispectRequestId: '42',
            'api_key': 'secret',
          },
        };

        NetworkMapRedactor.redactMapField(
          map,
          redactor,
          key: NetworkJsonKeys.extra,
          preserveKeys: {NetworkJsonKeys.ispectRequestId},
        );

        final extra = map[NetworkJsonKeys.extra];
        expect(extra, isA<Map<String, dynamic>>());
        expect(
          extra,
          containsPair(NetworkJsonKeys.ispectRequestId, '42'),
        );
        expect(extra.toString(), isNot(contains('secret')));
      });

      test('omits raw query parameters when a redactor returns null', () {
        const secret = 'NULL-QUERY-SECRET';
        final map = <String, dynamic>{
          NetworkJsonKeys.queryParameters: <String, dynamic>{
            'token': secret,
            'page': 1,
          },
        };

        NetworkMapRedactor.redactMapField(
          map,
          _NullMapRedactor(),
          key: NetworkJsonKeys.queryParameters,
        );

        expect(map[NetworkJsonKeys.queryParameters], <String, dynamic>{});
        expect(map.toString(), isNot(contains(secret)));
      });

      test('keeps only whitelisted Dio extra keys when redaction throws', () {
        const secret = 'THROWING-EXTRA-SECRET';
        final map = <String, dynamic>{
          NetworkJsonKeys.extra: <String, dynamic>{
            NetworkJsonKeys.ispectRequestId: 'request-42',
            'access_token': secret,
            'debug': true,
          },
        };

        NetworkMapRedactor.redactMapField(
          map,
          _ThrowingMapRedactor(),
          key: NetworkJsonKeys.extra,
          preserveKeys: {NetworkJsonKeys.ispectRequestId},
        );

        expect(map[NetworkJsonKeys.extra], <String, dynamic>{
          NetworkJsonKeys.ispectRequestId: 'request-42',
        });
        expect(map.toString(), isNot(contains(secret)));
      });

      test('does not traverse the raw map when no keys are preserved', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.extra: _ThrowOnIterationMap(),
        };

        NetworkMapRedactor.redactMapField(
          map,
          _NullExportMapRedactor(),
          key: NetworkJsonKeys.extra,
        );

        expect(map[NetworkJsonKeys.extra], <String, dynamic>{});
      });

      test('preserves only the exact string metadata key', () {
        final collidingKey = _CollidingRequestIdKey();
        final map = <String, dynamic>{
          NetworkJsonKeys.extra: <Object?, Object?>{
            NetworkJsonKeys.ispectRequestId: 'trusted-request-id',
            collidingKey: 'colliding-untrusted-value',
          },
        };

        NetworkMapRedactor.redactMapField(
          map,
          redactor,
          key: NetworkJsonKeys.extra,
          preserveKeys: {NetworkJsonKeys.ispectRequestId},
        );

        expect(
          map[NetworkJsonKeys.extra],
          containsPair(
            NetworkJsonKeys.ispectRequestId,
            'trusted-request-id',
          ),
        );
        expect(collidingKey.toStringCalls, 0);
      });

      for (final field in <String>[
        NetworkJsonKeys.queryParameters,
        NetworkJsonKeys.extra,
      ]) {
        test('bounds hostile nested values in $field before redaction', () {
          final hostile = _HostileDto();
          final key = _CollidingRequestIdKey();
          final map = <String, dynamic>{
            field: <Object?, Object?>{
              'visible': true,
              'huge': List.filled(
                LogExportOutput.maxRecordBytes,
                'x',
              ).join(),
              'nested': <String, Object?>{'dto': hostile},
              key: 'untrusted',
            },
          };

          NetworkMapRedactor.redactMapField(
            map,
            redactor,
            key: field,
          );

          final result = map[field] as Map<String, Object?>;
          expect(result['visible'], isTrue);
          expect(result['huge'], LogExportOutput.truncatedMarker);
          expect(hostile.toJsonCalls, 0);
          expect(hostile.toStringCalls, 0);
          expect(key.toStringCalls, 0);
        });
      }

      test('retains bounded map values for the explicit global opt-out', () {
        ISpectRedaction.enabled = false;
        final map = <String, dynamic>{
          NetworkJsonKeys.extra: <String, Object?>{
            'debug': 'visible-${List.filled(
              LogExportOutput.maxRecordBytes,
              'x',
            ).join()}',
          },
        };

        NetworkMapRedactor.redactMapField(
          map,
          redactor,
          key: NetworkJsonKeys.extra,
        );

        final extra = map[NetworkJsonKeys.extra] as Map<String, Object?>;
        expect(extra['debug'], startsWith('visible-'));
        expect(extra['debug'], contains(LogExportOutput.truncatedMarker));
      });

      test('no-op when field is null', () {
        final map = <String, dynamic>{NetworkJsonKeys.extra: null};

        NetworkMapRedactor.redactMapField(
          map,
          redactor,
          key: NetworkJsonKeys.extra,
        );

        expect(map[NetworkJsonKeys.extra], isNull);
      });
    });

    group('redactPathFields', () {
      test('redacts userInfo in base-url', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.baseUrl: 'https://user:pass@api.example.com',
          NetworkJsonKeys.path: '/users',
        };

        NetworkMapRedactor.redactPathFields(map, redactor);

        final baseUrl = map[NetworkJsonKeys.baseUrl] as String;
        expect(baseUrl, isNot(contains('user:pass')));
        expect(baseUrl, contains(userInfoRedactedPlaceholder));
      });

      test('no-op when base-url has no userInfo', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.baseUrl: 'https://api.example.com',
          NetworkJsonKeys.path: '/users',
        };

        NetworkMapRedactor.redactPathFields(map, redactor);

        expect(
          map[NetworkJsonKeys.baseUrl],
          'https://api.example.com',
        );
      });

      test('redacts query parameters in path and base-url', () {
        const secret = 'DUPLICATE-URL-SECRET';
        final map = <String, dynamic>{
          NetworkJsonKeys.baseUrl: 'https://api.example.com?api_key=$secret',
          NetworkJsonKeys.path: '/users?token=$secret',
        };

        NetworkMapRedactor.redactPathFields(map, redactor);

        expect(
          map[NetworkJsonKeys.baseUrl],
          isNot(contains(secret)),
        );
        expect(
          map[NetworkJsonKeys.path],
          isNot(contains(secret)),
        );
      });
    });

    group('redactFreeText', () {
      test('never executes hostile diagnostic conversion methods', () {
        final exception = _HostileException();
        final error = _HostileError();
        final stackTrace = _HostileStackTrace();
        final dto = _HostileDto();

        final outputs = <String>[
          NetworkMapRedactor.redactFreeTextValue(exception, redactor),
          NetworkMapRedactor.redactFreeTextValue(error, redactor),
          NetworkMapRedactor.redactFreeTextValue(stackTrace, redactor),
          NetworkMapRedactor.redactFreeTextValue(dto, redactor),
        ];

        expect(outputs, everyElement(isA<String>()));
        expect(exception.toStringCalls, 0);
        expect(error.toStringCalls, 0);
        expect(stackTrace.toStringCalls, 0);
        expect(dto.toJsonCalls, 0);
        expect(dto.toStringCalls, 0);
      });

      test('fails closed before scanning oversized diagnostic text', () {
        final output = NetworkMapRedactor.redactFreeTextValue(
          'visible-${List.filled(
            LogExportOutput.maxRecordBytes,
            'x',
          ).join()}',
          redactor,
        );

        expect(output, LogExportOutput.truncatedMarker);
      });

      test('retains bounded diagnostic text for the global opt-out', () {
        ISpectRedaction.enabled = false;

        final output = NetworkMapRedactor.redactFreeTextValue(
          'visible-${List.filled(
            LogExportOutput.maxRecordBytes,
            'x',
          ).join()}',
          redactor,
        );

        expect(output, startsWith('visible-'));
        expect(output, contains(LogExportOutput.truncatedMarker));
      });
    });

    group('redactRedirects', () {
      test('redacts location in redirect entries', () {
        final redirectEntry = <String, dynamic>{
          NetworkJsonKeys.location:
              'https://api.example.com/callback?token=secret',
          NetworkJsonKeys.statusCode: 302,
          NetworkJsonKeys.method: 'TRACE token=redirect-secret',
        };
        final map = <String, dynamic>{
          NetworkJsonKeys.redirects: [redirectEntry],
        };

        NetworkMapRedactor.redactRedirects(map, redactor);

        final redirects = map[NetworkJsonKeys.redirects] as List<Object?>;
        final redactedEntry = redirects.single! as Map<String, Object?>;
        final location = redactedEntry[NetworkJsonKeys.location]! as String;
        expect(location, isNot(contains('secret')));
        expect(
          redactedEntry[NetworkJsonKeys.method],
          isNot(contains('redirect-secret')),
        );
      });

      test('replaces redirect entries with bounded snapshots', () {
        final redirectEntry = <String, dynamic>{
          NetworkJsonKeys.location: 'https://example.com?key=val',
          NetworkJsonKeys.statusCode: 301,
        };
        final map = <String, dynamic>{
          NetworkJsonKeys.redirects: [redirectEntry],
        };

        NetworkMapRedactor.redactRedirects(map, redactor);

        final list = map[NetworkJsonKeys.redirects] as List;
        expect(identical(list.first, redirectEntry), isFalse);
        expect(
          (list.first as Map<String, Object?>)[NetworkJsonKeys.statusCode],
          301,
        );
      });

      test('bounds redirect lists and never stringifies hostile locations', () {
        final hostile = _HostileDto();
        final map = <String, dynamic>{
          NetworkJsonKeys.redirects: <Object?>[
            <String, Object?>{
              NetworkJsonKeys.location: hostile,
              'huge': List.filled(
                LogExportOutput.maxRecordBytes,
                'x',
              ).join(),
            },
          ],
        };

        NetworkMapRedactor.redactRedirects(map, redactor);

        final redirects = map[NetworkJsonKeys.redirects] as List<Object?>;
        final redirect = redirects.single! as Map<String, Object?>;
        expect(
          redirect['huge'],
          LogExportOutput.truncatedMarker,
        );
        expect(hostile.toJsonCalls, 0);
        expect(hostile.toStringCalls, 0);
      });

      test('no-op when redirects is absent', () {
        final map = <String, dynamic>{};

        NetworkMapRedactor.redactRedirects(map, redactor);

        expect(map.containsKey(NetworkJsonKeys.redirects), isFalse);
      });
    });

    group('applyCapturePolicy', () {
      test('breaks self-referential request maps', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.data: 'secret',
        };
        map[NetworkJsonKeys.request] = map;

        NetworkMapRedactor.applyCapturePolicy(
          map,
          includeData: false,
          includeHeaders: false,
          includeMessage: false,
          recursive: true,
        );

        expect(map.containsKey(NetworkJsonKeys.data), isFalse);
        expect(map.containsKey(NetworkJsonKeys.request), isFalse);
      });

      test('omits nested maps beyond the traversal depth budget', () {
        final root = <String, dynamic>{};
        var current = root;
        for (var index = 0; index < 70; index++) {
          final nested = <String, dynamic>{
            NetworkJsonKeys.data: 'deep-secret',
          };
          current[NetworkJsonKeys.response] = nested;
          current = nested;
        }

        NetworkMapRedactor.applyCapturePolicy(
          root,
          includeData: false,
          includeHeaders: false,
          includeMessage: false,
          recursive: true,
        );

        expect(root.toString(), isNot(contains('deep-secret')));
      });
    });

    group('redactMultipart', () {
      test('redacts multipart fields', () {
        final map = <String, dynamic>{
          NetworkJsonKeys.multipartRequest: <String, dynamic>{
            NetworkJsonKeys.fields: <String, dynamic>{
              'password': 'secret123',
              'username': 'john',
            },
            NetworkJsonKeys.files: <Map<String, Object?>>[
              {
                'field': 'avatar',
                'filename': 'photo.jpg',
                'contentType': 'image/jpeg',
                'length': 1024,
              },
            ],
          },
        };

        NetworkMapRedactor.redactMultipart(map, redactor);

        final mp =
            map[NetworkJsonKeys.multipartRequest] as Map<String, dynamic>;
        final fields = mp[NetworkJsonKeys.fields] as Map<dynamic, dynamic>;
        expect(fields['password'], isNot('secret123'));
      });

      test('no-op when multipart-request is absent', () {
        final map = <String, dynamic>{};

        NetworkMapRedactor.redactMultipart(map, redactor);

        expect(
          map.containsKey(NetworkJsonKeys.multipartRequest),
          isFalse,
        );
      });

      test('bounds multipart fields and files before redaction', () {
        final fieldDto = _HostileDto();
        final fileDto = _HostileDto();
        final key = _CollidingRequestIdKey();
        final fieldsMap = <String, dynamic>{
          NetworkJsonKeys.multipartRequest: <String, Object?>{
            NetworkJsonKeys.fields: <Object?, Object?>{
              'huge': List.filled(
                LogExportOutput.maxRecordBytes,
                'x',
              ).join(),
              'dto': fieldDto,
              key: 'untrusted',
            },
            NetworkJsonKeys.files: <Object?>[],
          },
        };
        final filesMap = <String, dynamic>{
          NetworkJsonKeys.multipartRequest: <String, Object?>{
            NetworkJsonKeys.fields: <String, Object?>{},
            NetworkJsonKeys.files: <Object?>[
              <String, Object?>{
                'filename': List.filled(
                  LogExportOutput.maxRecordBytes,
                  'x',
                ).join(),
                'dto': fileDto,
              },
            ],
          },
        };

        NetworkMapRedactor.redactMultipart(fieldsMap, redactor);
        NetworkMapRedactor.redactMultipart(filesMap, redactor);

        final fieldsMultipart =
            fieldsMap[NetworkJsonKeys.multipartRequest] as Map<String, Object?>;
        final fields =
            fieldsMultipart[NetworkJsonKeys.fields]! as Map<String, Object?>;
        final filesMultipart =
            filesMap[NetworkJsonKeys.multipartRequest] as Map<String, Object?>;
        final files = filesMultipart[NetworkJsonKeys.files]! as List<Object?>;
        final file = files.single! as Map<String, Object?>;
        expect(fields['huge'], LogExportOutput.truncatedMarker);
        expect(
          file['filename'],
          anyOf(
            LogExportOutput.truncatedMarker,
            defaultPlaceholder,
          ),
        );
        expect(fieldDto.toJsonCalls, 0);
        expect(fieldDto.toStringCalls, 0);
        expect(fileDto.toJsonCalls, 0);
        expect(fileDto.toStringCalls, 0);
        expect(key.toStringCalls, 0);
      });

      test('retains bounded multipart prefixes for the global opt-out', () {
        ISpectRedaction.enabled = false;
        final map = <String, dynamic>{
          NetworkJsonKeys.multipartRequest: <String, Object?>{
            NetworkJsonKeys.fields: <String, Object?>{
              'debug': 'visible-${List.filled(
                LogExportOutput.maxRecordBytes,
                'x',
              ).join()}',
            },
            NetworkJsonKeys.files: <Object?>[],
          },
        };

        NetworkMapRedactor.redactMultipart(map, redactor);

        final multipart =
            map[NetworkJsonKeys.multipartRequest] as Map<String, Object?>;
        final fields =
            multipart[NetworkJsonKeys.fields]! as Map<String, Object?>;
        expect(fields['debug'], startsWith('visible-'));
        expect(fields['debug'], contains(LogExportOutput.truncatedMarker));
      });

      for (final failingRedactor in <RedactionService>[
        _NullMapRedactor(),
        _ThrowingMapRedactor(),
      ]) {
        test(
          'omits multipart secrets when ${failingRedactor.runtimeType} fails',
          () {
            const secret = 'MULTIPART-FAIL-CLOSED-SECRET';
            final map = <String, dynamic>{
              NetworkJsonKeys.multipartRequest: <String, dynamic>{
                NetworkJsonKeys.fields: <String, dynamic>{
                  'password': secret,
                },
                NetworkJsonKeys.files: <Map<String, Object?>>[
                  {'filename': '$secret.txt'},
                ],
              },
            };

            NetworkMapRedactor.redactMultipart(map, failingRedactor);

            final multipart =
                map[NetworkJsonKeys.multipartRequest] as Map<String, dynamic>;
            expect(multipart[NetworkJsonKeys.fields], isEmpty);
            expect(multipart[NetworkJsonKeys.files], isEmpty);
            expect(multipart.toString(), isNot(contains(secret)));
          },
        );
      }
    });
  });
}
