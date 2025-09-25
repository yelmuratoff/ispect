import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/settings.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectHttpInterceptorSettings', () {
    test('copyWith should create a new instance with the provided values', () {
      const originalSettings = ISpectHttpInterceptorSettings();
      final updatedSettings = originalSettings.copyWith(
        printResponseData: false,
        printRequestHeaders: true,
        printErrorHeaders: false,
        requestPen: AnsiPen()..yellow(),
      );

      expect(updatedSettings.printResponseData, equals(false));
      expect(updatedSettings.printRequestHeaders, equals(true));
      expect(updatedSettings.printErrorHeaders, equals(false));
      expect(
        updatedSettings.requestPen,
        isNot(same(originalSettings.requestPen)),
      );
      expect(updatedSettings.responseFilter, isNull);
    });

    test('copyWith preserves enabled flag when changing other settings', () {
      // Test with enabled = false
      const disabledSettings = ISpectHttpInterceptorSettings(enabled: false);
      final updatedDisabledSettings = disabledSettings.copyWith(
        printResponseData: false,
        printRequestHeaders: true,
      );

      expect(updatedDisabledSettings.enabled, equals(false));
      expect(updatedDisabledSettings.printResponseData, equals(false));
      expect(updatedDisabledSettings.printRequestHeaders, equals(true));

      // Test with enabled = true (default)
      const enabledSettings = ISpectHttpInterceptorSettings();
      final updatedEnabledSettings = enabledSettings.copyWith(
        printErrorHeaders: false,
        printRequestData: false,
      );

      expect(updatedEnabledSettings.enabled, equals(true));
      expect(updatedEnabledSettings.printErrorHeaders, equals(false));
      expect(updatedEnabledSettings.printRequestData, equals(false));
    });

    test('requestFilter should return true for allowed paths', () {
      final settings = ISpectHttpInterceptorSettings(
        requestFilter: (request) => request.url.path == '/allowed',
      );
      final allowedRequest =
          Request('GET', Uri.parse('https://example.com/allowed'));
      final disallowedRequest =
          Request('GET', Uri.parse('https://example.com/disallowed'));

      expect(settings.requestFilter!(allowedRequest), equals(true));
      expect(settings.requestFilter!(disallowedRequest), equals(false));
    });

    test('responseFilter should return true for successful responses', () {
      final settings = ISpectHttpInterceptorSettings(
        responseFilter: (response) => response.statusCode == 200,
      );
      final successfulResponse = Response('OK', 200);
      final unsuccessfulResponse = Response('Not Found', 404);

      expect(settings.responseFilter!(successfulResponse), equals(true));
      expect(settings.responseFilter!(unsuccessfulResponse), equals(false));
    });

    test('errorFilter should return true for error responses', () {
      final settings = ISpectHttpInterceptorSettings(
        errorFilter: (response) => response.statusCode == 500,
      );
      final errorResponse = Response('Internal Server Error', 500);
      final clientErrorResponse = Response('Bad Request', 400);

      expect(settings.errorFilter!(errorResponse), equals(true));
      expect(settings.errorFilter!(clientErrorResponse), equals(false));
    });
  });
}
