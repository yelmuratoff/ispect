import 'package:http/http.dart' as http;
import 'package:ispectify_http/src/data/request.dart';
import 'package:ispectify_http/src/data/response.dart';
import 'package:ispectify_http/src/models/response.dart';
import 'package:ispectify_http/src/settings.dart';
import 'package:test/test.dart';

void main() {
  group('HTTP header toggle serialization', () {
    test('Response additionalData omits headers when disabled', () {
      final request = http.Request('GET', Uri.parse('https://example.com'))
        ..headers['Authorization'] = 'Bearer token';
      final response = http.Response(
        'ok',
        200,
        request: request,
        headers: {
          'content-type': 'application/json',
        },
      );

      const settings = ISpectHttpInterceptorSettings();

      final log = HttpResponseLog(
        'https://example.com',
        method: 'GET',
        url: 'https://example.com',
        path: '/path',
        statusCode: 200,
        statusMessage: 'OK',
        requestHeaders: null,
        headers: null,
        requestBody: null,
        responseBody: null,
        settings: settings,
        responseData: HttpResponseData(
          baseResponse: response,
          response: response,
          requestData: HttpRequestData(request),
          multipartRequest: null,
        ),
      );

      final additional = log.additionalData!;
      expect(additional.containsKey('headers'), isFalse);
      final req = additional['request-data'] as Map<String, dynamic>;
      expect(req.containsKey('headers'), isFalse);
    });
  });
}
