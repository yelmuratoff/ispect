import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  late RedactionService redactor;

  setUp(() {
    redactor = RedactionService();
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
        if (extra is Map<String, dynamic>) {
          expect(extra[NetworkJsonKeys.ispectRequestId], '42');
        }
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
    });

    group('redactRedirects', () {
      test('redacts location in redirect entries', () {
        final redirectEntry = <String, dynamic>{
          NetworkJsonKeys.location:
              'https://api.example.com/callback?token=secret',
          NetworkJsonKeys.statusCode: 302,
          NetworkJsonKeys.method: 'GET',
        };
        final map = <String, dynamic>{
          NetworkJsonKeys.redirects: [redirectEntry],
        };

        NetworkMapRedactor.redactRedirects(map, redactor);

        final location =
            redirectEntry[NetworkJsonKeys.location]?.toString() ?? '';
        expect(location, isNot(contains('secret')));
      });

      test('mutates redirect maps in place', () {
        final redirectEntry = <String, dynamic>{
          NetworkJsonKeys.location: 'https://example.com?key=val',
          NetworkJsonKeys.statusCode: 301,
        };
        final map = <String, dynamic>{
          NetworkJsonKeys.redirects: [redirectEntry],
        };

        NetworkMapRedactor.redactRedirects(map, redactor);

        // The same list and entry objects are still in the map.
        final list = map[NetworkJsonKeys.redirects] as List;
        expect(identical(list.first, redirectEntry), isTrue);
      });

      test('no-op when redirects is absent', () {
        final map = <String, dynamic>{};

        NetworkMapRedactor.redactRedirects(map, redactor);

        expect(map.containsKey(NetworkJsonKeys.redirects), isFalse);
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
    });
  });
}
