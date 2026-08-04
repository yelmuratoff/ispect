// ignore_for_file: deprecated_member_use_from_same_package
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectHttpInterceptorSettings', () {
    test('copyWith should create a new instance with the provided values', () {
      const originalSettings = ISpectHttpInterceptorSettings();
      final updatedSettings = originalSettings.copyWith(
        logRequests: false,
        logResponses: false,
        printResponseData: false,
        printRequestHeaders: true,
        printErrorHeaders: false,
        captureMode: DiagnosticCaptureMode.strict,
        requestPen: AnsiPen()..yellow(),
      );

      expect(updatedSettings.logRequests, isFalse);
      expect(updatedSettings.logResponses, isFalse);
      expect(updatedSettings.printResponseData, equals(false));
      expect(updatedSettings.printRequestHeaders, equals(true));
      expect(updatedSettings.printErrorHeaders, equals(false));
      expect(updatedSettings.captureMode, DiagnosticCaptureMode.strict);
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

    test('copyWith preserves and replaces adapter resource limits', () {
      const original = ISpectHttpInterceptorSettings(
        resourceLimits: DiagnosticResourceLimits.constrained,
      );

      expect(
        original.copyWith().resourceLimits,
        same(DiagnosticResourceLimits.constrained),
      );
      expect(
        original
            .copyWith(resourceLimits: DiagnosticResourceLimits.extended)
            .resourceLimits,
        same(DiagnosticResourceLimits.extended),
      );
      expect(
        original
            .copyWith(
              resourceLimits: DiagnosticResourceLimits.extended,
              inheritResourceLimits: true,
            )
            .resourceLimits,
        isNull,
      );
    });

    test('interceptor configure updates the shared capture contract', () {
      final interceptor = ISpectHttpInterceptor()
        ..configure(
          enabled: false,
          captureMode: DiagnosticCaptureMode.strict,
          resourceLimits: DiagnosticResourceLimits.constrained,
          logRequests: false,
          logResponses: false,
          printRequestData: false,
          printRequestHeaders: false,
        );

      expect(interceptor.settings.enabled, isFalse);
      expect(
        interceptor.settings.captureMode,
        DiagnosticCaptureMode.strict,
      );
      expect(
        interceptor.settings.resourceLimits,
        same(DiagnosticResourceLimits.constrained),
      );
      expect(interceptor.settings.logRequests, isFalse);
      expect(interceptor.settings.logResponses, isFalse);
      expect(interceptor.settings.printRequestData, isFalse);
      expect(interceptor.settings.printRequestHeaders, isFalse);

      interceptor.configure(inheritResourceLimits: true);

      expect(interceptor.settings.resourceLimits, isNull);
    });
  });
}
