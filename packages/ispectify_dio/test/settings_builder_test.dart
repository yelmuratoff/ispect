// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectDioInterceptorSettingsBuilder', () {
    test('default constructor captures full redacted diagnostics', () {
      final settings = ISpectDioInterceptorSettingsBuilder().build();

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
          ISpectDioInterceptorSettingsBuilder.metadataOnly().build();

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
          ISpectDioInterceptorSettingsBuilder.development().build();

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
      final settings = ISpectDioInterceptorSettingsBuilder.production().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.logRequests, false);
      expect(settings.logResponses, false);
      expect(settings.printRequestData, false);
      expect(settings.printResponseData, false);
      expect(settings.printErrorData, false);
      expect(settings.printErrorHeaders, false);
      expect(settings.printErrorMessage, true);
      expect(settings.captureMode, DiagnosticCaptureMode.strict);
    });

    test('staging() creates balanced settings with redaction', () {
      final settings = ISpectDioInterceptorSettingsBuilder.staging().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.logRequests, true);
      expect(settings.logResponses, false);
      expect(settings.printRequestData, true);
      expect(settings.printErrorData, true);
      expect(settings.captureMode, DiagnosticCaptureMode.balanced);
    });

    test('disabled() creates disabled settings', () {
      final settings = ISpectDioInterceptorSettingsBuilder.disabled().build();

      expect(settings.enabled, false);
    });

    test('withRedaction() enables redaction', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withRedaction().build();

      expect(settings.enableRedaction, true);
    });

    test('withoutRedaction() disables redaction', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withoutRedaction().build();

      expect(settings.enableRedaction, false);
    });

    test('withStrictCapture() opts out of application formatters', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withStrictCapture().build();

      expect(settings.captureMode, DiagnosticCaptureMode.strict);
    });

    test('withResourceLimits() stores an adapter override', () {
      final settings = ISpectDioInterceptorSettingsBuilder()
          .withResourceLimits(DiagnosticResourceLimits.constrained)
          .build();

      expect(
        settings.resourceLimits,
        same(DiagnosticResourceLimits.constrained),
      );
    });

    test('withAllHeaders() enables all header printing', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withAllHeaders().build();

      expect(settings.printRequestHeaders, true);
      expect(settings.printResponseHeaders, true);
      expect(settings.printErrorHeaders, true);
    });

    test('withAllData() enables all data printing', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withAllData().build();

      expect(settings.printRequestData, true);
      expect(settings.printResponseData, true);
      expect(settings.printErrorData, true);
    });

    test('individual opt-outs omit every optional payload field', () {
      final settings = ISpectDioInterceptorSettingsBuilder()
          .withoutRequestData()
          .withoutRequestHeaders()
          .withoutResponseData()
          .withoutResponseHeaders()
          .withoutResponseMessage()
          .withoutErrorData()
          .withoutErrorHeaders()
          .withoutErrorMessage()
          .build();

      expect(settings.printRequestData, isFalse);
      expect(settings.printRequestHeaders, isFalse);
      expect(settings.printResponseData, isFalse);
      expect(settings.printResponseHeaders, isFalse);
      expect(settings.printResponseMessage, isFalse);
      expect(settings.printErrorData, isFalse);
      expect(settings.printErrorHeaders, isFalse);
      expect(settings.printErrorMessage, isFalse);
    });

    test('bulk opt-outs omit all headers and data', () {
      final settings = ISpectDioInterceptorSettingsBuilder()
          .withoutAllHeaders()
          .withoutAllData()
          .build();

      expect(settings.printRequestHeaders, isFalse);
      expect(settings.printResponseHeaders, isFalse);
      expect(settings.printErrorHeaders, isFalse);
      expect(settings.printRequestData, isFalse);
      expect(settings.printResponseData, isFalse);
      expect(settings.printErrorData, isFalse);
    });

    test('withErrorsOnly() disables request/response logging', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withErrorsOnly().build();

      expect(settings.printRequestData, false);
      expect(settings.printRequestHeaders, false);
      expect(settings.printResponseData, false);
      expect(settings.printResponseHeaders, false);
      expect(settings.logRequests, false);
      expect(settings.logResponses, false);
      expect(settings.printErrorData, true);
      expect(settings.printErrorHeaders, true);
    });

    test('withRequestPen() sets custom request color', () {
      final bluePen = AnsiPen()..blue();
      final settings =
          ISpectDioInterceptorSettingsBuilder().withRequestPen(bluePen).build();

      expect(settings.requestPen, bluePen);
    });

    test('withResponsePen() sets custom response color', () {
      final greenPen = AnsiPen()..green();
      final settings = ISpectDioInterceptorSettingsBuilder()
          .withResponsePen(greenPen)
          .build();

      expect(settings.responsePen, greenPen);
    });

    test('withErrorPen() sets custom error color', () {
      final redPen = AnsiPen()..red();
      final settings =
          ISpectDioInterceptorSettingsBuilder().withErrorPen(redPen).build();

      expect(settings.errorPen, redPen);
    });

    test('withRequestFilter() sets custom request filter', () {
      bool filter(RequestOptions options) => options.path.contains('/api/');
      final settings = ISpectDioInterceptorSettingsBuilder()
          .withRequestFilter(filter)
          .build();

      expect(settings.requestFilter, isNotNull);
    });

    test('method chaining works correctly', () {
      final settings = ISpectDioInterceptorSettingsBuilder()
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
