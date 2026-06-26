import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

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

    test('flags a redacted body and omits it', () {
      final parsed = NetworkReplayRequestParser.fromRequestMap({
        NetworkJsonKeys.method: 'POST',
        NetworkJsonKeys.url: 'https://api.example.com/login',
        NetworkJsonKeys.data: defaultPlaceholder,
      });

      expect(parsed!.bodyRedacted, isTrue);
      expect(parsed.request.body, isNull);
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
  });
}
