import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:ispectify_http/src/settings.dart';
import 'package:test/test.dart';

void main() {
  group('HttpResponseLog', () {
    test('textMessage uses responseBody, not requestBody', () {
      const settings = ISpectHttpInterceptorSettings(
        printResponseMessage: false,
      );

      final log = HttpResponseLog(
        'https://example.com',
        method: 'GET',
        url: 'https://example.com',
        path: '/path',
        statusCode: 200,
        statusMessage: 'OK',
        requestHeaders: null,
        headers: null,
        requestBody: const {'shouldNotAppear': true},
        responseBody: const {'hello': 'world'},
        settings: settings,
        responseData: null,
      );

      final text = log.textMessage;
      expect(
        text.contains('hello'),
        isTrue,
        reason: 'Response body should be present in output',
      );
      expect(
        text.contains('shouldNotAppear'),
        isFalse,
        reason: 'Request body must not be shown in response log',
      );
    });
  });

  group('ISpectHttpInterceptor', () {
    test('logs parsed response body for success responses', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: false,
          printResponseMessage: false,
          enableRedaction: false,
        ),
      );

      final request = http.Request('GET', Uri.parse('https://example.com'));
      final response = http.Response(
        '{"foo": 123}',
        200,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpResponseLog)
          .cast<HttpResponseLog>()
          .first;

      await interceptor.interceptResponse(response: response);

      final log = await future;
      expect(
        log.responseBody,
        isA<Map<String, dynamic>>(),
        reason: 'Response body should be decoded to Map',
      );
      expect(
        log.textMessage.contains('foo'),
        isTrue,
        reason: 'Pretty-printed response body should be in text output',
      );
    });

    test('error logs preserve array bodies under data key', () async {
      final inspector = ISpectify();
      final interceptor = ISpectHttpInterceptor(
        logger: inspector,
        settings: const ISpectHttpInterceptorSettings(
          printResponseData: true,
          printErrorData: true,
          enableRedaction: false,
        ),
      );

      final request =
          http.Request('POST', Uri.parse('https://api.example.com/login'));
      final response = http.Response(
        '[{"field":"email","message":"Invalid"},{"field":"password","message":"Too short"}]',
        422,
        request: request,
      );

      final future = inspector.stream
          .where((e) => e is HttpErrorLog)
          .cast<HttpErrorLog>()
          .first;

      await interceptor.interceptResponse(response: response);

      final log = await future;
      expect(log.body, isNotNull);
      expect(log.body, contains('data'));
      final data = log.body!['data'];
      expect(data, isA<List<dynamic>>());
      expect(log.textMessage.contains('email'), isTrue,
          reason: 'Array error content should appear in formatted text');
    });
  });
}
