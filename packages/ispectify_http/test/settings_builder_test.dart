import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectHttpInterceptorSettingsBuilder', () {
    test('default constructor captures full redacted diagnostics', () {
      final settings = ISpectHttpInterceptorSettingsBuilder().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.logRequests, true);
      expect(settings.logResponses, true);
      expect(settings.printResponseData, true);
      expect(settings.printResponseHeaders, true);
      expect(settings.printRequestData, true);
      expect(settings.printRequestHeaders, true);
      expect(settings.printErrorData, true);
      expect(settings.printErrorHeaders, true);
      expect(settings.captureMode, DiagnosticCaptureMode.balanced);
    });

    test('metadataOnly() opts into payload minimization with redaction', () {
      final settings =
          ISpectHttpInterceptorSettingsBuilder.metadataOnly().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.logRequests, true);
      expect(settings.logResponses, true);
      expect(settings.printResponseData, false);
      expect(settings.printResponseHeaders, false);
      expect(settings.printRequestData, false);
      expect(settings.printRequestHeaders, false);
      expect(settings.printErrorData, false);
      expect(settings.printErrorHeaders, false);
      expect(settings.captureMode, DiagnosticCaptureMode.strict);
    });

    test('development() creates verbose settings with redaction', () {
      final settings =
          ISpectHttpInterceptorSettingsBuilder.development().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.logRequests, true);
      expect(settings.logResponses, true);
      expect(settings.printResponseHeaders, true);
      expect(settings.printRequestHeaders, true);
      expect(settings.printErrorHeaders, true);
      expect(settings.printResponseData, true);
      expect(settings.printRequestData, true);
      expect(settings.printErrorData, true);
      expect(settings.captureMode, DiagnosticCaptureMode.balanced);
    });

    test('production() creates minimal settings with redaction', () {
      final settings =
          ISpectHttpInterceptorSettingsBuilder.production().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.printRequestData, false);
      expect(settings.printResponseData, false);
      expect(settings.logRequests, false);
      expect(settings.logResponses, false);
      expect(settings.printErrorData, false);
      expect(settings.printErrorHeaders, false);
      expect(settings.printErrorMessage, true);
      expect(settings.captureMode, DiagnosticCaptureMode.strict);
    });

    test('staging() creates balanced settings with redaction', () {
      final settings = ISpectHttpInterceptorSettingsBuilder.staging().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.logRequests, true);
      expect(settings.logResponses, false);
      expect(settings.printRequestData, true);
      expect(settings.printErrorData, true);
      expect(settings.captureMode, DiagnosticCaptureMode.balanced);
    });

    test('disabled() creates disabled settings', () {
      final settings = ISpectHttpInterceptorSettingsBuilder.disabled().build();

      expect(settings.enabled, false);
    });

    test('withAllHeaders() enables all header printing', () {
      final settings =
          ISpectHttpInterceptorSettingsBuilder().withAllHeaders().build();

      expect(settings.printRequestHeaders, true);
      expect(settings.printResponseHeaders, true);
      expect(settings.printErrorHeaders, true);
    });

    test('withStrictCapture() opts out of application formatters', () {
      final settings =
          ISpectHttpInterceptorSettingsBuilder().withStrictCapture().build();

      expect(settings.captureMode, DiagnosticCaptureMode.strict);
    });

    test('withErrorsOnly() disables request/response logging', () {
      final settings =
          ISpectHttpInterceptorSettingsBuilder().withErrorsOnly().build();

      expect(settings.printRequestData, false);
      expect(settings.printResponseData, false);
      expect(settings.logRequests, false);
      expect(settings.logResponses, false);
      expect(settings.printErrorData, true);
    });

    test('method chaining works correctly', () {
      final settings = ISpectHttpInterceptorSettingsBuilder()
          .withRedaction()
          .withRequestHeaders()
          .withResponseHeaders()
          .withErrorsOnly()
          .build();

      expect(settings.enableRedaction, true);
      expect(settings.printErrorData, true);
      expect(settings.printRequestData, false);
    });
  });
}
