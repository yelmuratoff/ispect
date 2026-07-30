import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _HostileReplayValue {
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Object? toJson() {
    toJsonCalls++;
    return 'HOSTILE-REPLAY-SECRET';
  }

  @override
  String toString() {
    toStringCalls++;
    return 'HOSTILE-REPLAY-SECRET';
  }
}

void main() {
  group('NetworkReplayRequestParser.fromRequestMap', () {
    test('reconstructs method, url, headers and JSON body from a Dio map', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'post',
        NetworkJsonKeys.url: 'https://api.example.com/users',
        NetworkJsonKeys.headers: {'Accept': 'application/json'},
        NetworkJsonKeys.contentType: 'application/json',
        NetworkJsonKeys.data: {'name': 'Ada'},
      });

      expect(parsed, isNotNull);
      final request = parsed!.request;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'https://api.example.com/users');
      expect(request.headers['Accept'], 'application/json');
      expect(request.body, isA<JsonReplayBody>());
      expect((request.body! as JsonReplayBody).value, {'name': 'Ada'});
    });

    test('merges separate query-parameters into the uri', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/search',
        NetworkJsonKeys.queryParameters: {'q': 'dart', 'page': 2},
      });

      final uri = parsed!.request.uri;
      expect(uri.queryParameters['q'], 'dart');
      expect(uri.queryParameters['page'], '2');
    });

    test('drops redacted header values and records their keys', () {
      // Legacy '***' mask from pre-unification captures must still be detected.
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/me',
        NetworkJsonKeys.headers: {
          'Authorization': '***',
          'Accept': 'application/json',
        },
      });

      expect(parsed!.request.headers.containsKey('Authorization'), isFalse);
      expect(parsed.request.headers['Accept'], 'application/json');
      expect(parsed.redactedHeaderKeys, contains('Authorization'));
    });

    test('drops headers containing embedded and edge redaction markers', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/me',
        NetworkJsonKeys.headers: {
          'Authorization': 'Bearer $defaultPlaceholder',
          'X-Api-Key': 'ab…yz ($defaultPlaceholder)',
          'Accept': 'application/json',
        },
      });

      expect(parsed!.request.headers, {'Accept': 'application/json'});
      expect(
        parsed.redactedHeaderKeys,
        containsAll(<String>['Authorization', 'X-Api-Key']),
      );
    });

    test('uses provenance for custom-placeholder header redaction', () {
      final captured = <String, dynamic>{
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/me',
        NetworkJsonKeys.headers: {
          'Authorization': 'Bearer HEADER_SECRET',
          'Accept': 'application/json',
        },
      };
      NetworkMapRedactor.redactHeaders(
        captured,
        RedactionService(placeholder: 'MASKED'),
      );

      final parsed = NetworkReplayRequestParser.fromRequestMap(captured);

      expect(parsed, isNotNull);
      expect(parsed!.request.headers, {'Accept': 'application/json'});
      expect(parsed.redactedHeaderKeys, contains('Authorization'));
      expect(captured.toString(), isNot(contains('HEADER_SECRET')));
    });

    test('rejects a redacted header name using only its safe provenance label',
        () {
      const rawName = 'tenantSecret=REPLAY-HEADER-NAME-SECRET';
      const safeName = '<REPLAY_HEADER_NAME>';
      final captured = <String, dynamic>{
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/me',
        NetworkJsonKeys.headers: const <String, Object?>{
          rawName: 'visible',
        },
      };
      NetworkMapRedactor.redactHeaders(
        captured,
        RedactionService(
          sensitiveKeys: const {'tenantSecret'},
          sensitiveKeyPatterns: const <RegExp>[],
          placeholder: '<REPLAY_HEADER_NAME>',
        ),
      );

      final parsed = NetworkReplayRequestParser.fromRequestMap(captured);

      expect(parsed, isNotNull);
      expect(parsed!.request.headers, isEmpty);
      expect(parsed.redactedHeaderKeys, contains(safeName));
      expect(parsed.redactedHeaderKeys, isNot(contains(rawName)));
      expect(captured.toString(), isNot(contains(rawName)));
      expect(
        captured.toString(),
        isNot(contains('REPLAY-HEADER-NAME-SECRET')),
      );
    });

    test('always omits sensitive legacy headers with unknown placeholders', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/me',
        NetworkJsonKeys.headers: {
          'Authorization': 'Bearer CUSTOM_MASK',
          'X-Api-Key': 'CUSTOM_MASK',
          'Accept': 'application/json',
        },
      });

      expect(parsed!.request.headers, {'Accept': 'application/json'});
      expect(
        parsed.redactedHeaderKeys,
        containsAll(<String>['Authorization', 'X-Api-Key']),
      );
    });

    test('flags a redacted body and omits it', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/login',
        NetworkJsonKeys.data: defaultPlaceholder,
      });

      expect(parsed!.bodyRedacted, isTrue);
      expect(parsed.request.body, isNull);
    });

    test('flags and omits JSON bodies containing nested safety markers', () {
      for (final marker in [
        defaultPlaceholder,
        redactionFailedPlaceholder,
        LogExportOutput.truncatedMarker,
        binaryPlaceholder(128),
      ]) {
        final parsed = NetworkReplayRequestParser.fromRequestMap({
          NetworkJsonKeys.method: 'POST',
          NetworkJsonKeys.url: 'https://api.example.com/login',
          NetworkJsonKeys.data: {
            'safe': 'visible',
            'nested': [
              {'credential': 'Bearer $marker'},
            ],
          },
        });

        expect(parsed!.bodyRedacted, isTrue);
        expect(parsed.request.body, isNull);
      }
    });

    test('uses provenance for a custom-placeholder nested body', () {
      final captured = <String, dynamic>{
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/login',
        NetworkJsonKeys.data: {
          'profile': {'password': 'BODY_SECRET'},
        },
      };
      NetworkMapRedactor.redactData(
        captured,
        RedactionService(placeholder: 'MASKED'),
      );

      final parsed = NetworkReplayRequestParser.fromRequestMap(captured);

      expect(parsed, isNotNull);
      expect(parsed!.bodyRedacted, isTrue);
      expect(parsed.request.body, isNull);
      expect(captured.toString(), isNot(contains('BODY_SECRET')));
    });

    test('rejects custom-placeholder query redaction via provenance', () {
      final captured = <String, dynamic>{
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/search',
        NetworkJsonKeys.queryParameters: {'token': 'QUERY_SECRET'},
      };
      NetworkMapRedactor.redactMapField(
        captured,
        RedactionService(placeholder: 'MASKED'),
        key: NetworkJsonKeys.queryParameters,
      );

      expect(
        NetworkReplayRequestParser.fromRequestMap(captured),
        isNull,
      );
      expect(captured.toString(), isNot(contains('QUERY_SECRET')));
    });

    test('rejects custom-placeholder URL redaction via provenance', () {
      final captured = <String, dynamic>{
        NetworkJsonKeys.method: 'GET',
        NetworkJsonKeys.url: 'https://api.example.com/search?token=URL_SECRET',
      };
      NetworkMapRedactor.redactUrl(
        captured,
        RedactionService(placeholder: 'MASKED'),
      );

      expect(
        NetworkReplayRequestParser.fromRequestMap(captured),
        isNull,
      );
      expect(captured.toString(), isNot(contains('URL_SECRET')));
    });

    test('parses a form-urlencoded string body', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/form',
        NetworkJsonKeys.contentType: 'application/x-www-form-urlencoded',
        NetworkJsonKeys.body: 'a=1&b=two',
      });

      final body = parsed!.request.body;
      expect(body, isA<FormUrlEncodedReplayBody>());
      final fields = (body! as FormUrlEncodedReplayBody).fields;
      expect(fields, {'a': '1', 'b': 'two'});
    });

    test('fails closed for malformed form-urlencoded escapes', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/form',
        NetworkJsonKeys.contentType: 'application/x-www-form-urlencoded',
        NetworkJsonKeys.body: 'safe=value&secret=%ZZ',
      });

      expect(parsed, isNotNull);
      expect(parsed!.request.body, isNull);
      expect(parsed.bodyRedacted, isTrue);
    });

    test('restores multipart text fields', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/upload',
        NetworkJsonKeys.multipartRequest: {
          NetworkJsonKeys.fields: {'title': 'photo'},
        },
      });

      final body = parsed!.request.body;
      expect(body, isA<MultipartReplayBody>());
      final fields = (body! as MultipartReplayBody).fields;
      expect(fields.single.name, 'title');
      expect(fields.single.value, 'photo');
    });

    test('returns null when the map has no usable url', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'GET',
      });

      expect(parsed, isNull);
    });

    test('never formats hostile replay values', () {
      final header = _HostileReplayValue();
      final body = _HostileReplayValue();

      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/safe',
        NetworkJsonKeys.headers: {'X-Hostile': header},
        NetworkJsonKeys.data: body,
      });

      expect(parsed, isNotNull);
      expect(parsed!.request.headers, isEmpty);
      expect(parsed.request.body, isNull);
      expect(parsed.bodyRedacted, isTrue);
      expect(header.toJsonCalls, 0);
      expect(header.toStringCalls, 0);
      expect(body.toJsonCalls, 0);
      expect(body.toStringCalls, 0);
    });

    test('rejects oversized and truncated replay destinations and bodies', () {
      final oversized = 'x' * (4 * 1024 * 1024);

      expect(
        NetworkReplayRequestParser.fromRequestMap({
          NetworkJsonKeys.url: 'https://api.example.com/$oversized',
        }),
        isNull,
      );

      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/safe',
        NetworkJsonKeys.data: oversized,
      });
      expect(parsed!.bodyRedacted, isTrue);
      expect(parsed.request.body, isNull);
    });

    test('honors custom replay header and body budgets', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxNetworkHeaders: 2,
        maxNetworkBodyBytes: 64,
      );

      final parsed = NetworkReplayRequestParser.fromRequestMap(
        {
          NetworkJsonKeys.method: 'POST',
          NetworkJsonKeys.url: 'https://api.example.com/safe',
          NetworkJsonKeys.headers: {
            'X-First': '1',
            'X-Second': '2',
            'X-Third': '3',
          },
          NetworkJsonKeys.data: 'x' * 200,
        },
        resourceLimits: limits,
      );

      expect(parsed, isNotNull);
      expect(parsed!.request.headers, {'X-First': '1', 'X-Second': '2'});
      expect(parsed.request.body, isNull);
      expect(parsed.bodyRedacted, isTrue);
    });
  });
}
