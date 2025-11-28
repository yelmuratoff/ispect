import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectDioInterceptorSettingsBuilder', () {
    test('default constructor creates moderate verbosity settings', () {
      final settings = ISpectDioInterceptorSettingsBuilder().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, false);
      expect(settings.printResponseData, true);
      expect(settings.printResponseHeaders, false);
      expect(settings.printRequestData, true);
      expect(settings.printRequestHeaders, false);
      expect(settings.printErrorData, true);
    });

    test('development() creates verbose settings without redaction', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder.development().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, false);
      expect(settings.printResponseHeaders, true);
      expect(settings.printRequestHeaders, true);
      expect(settings.printErrorHeaders, true);
      expect(settings.printResponseData, true);
      expect(settings.printRequestData, true);
      expect(settings.printErrorData, true);
    });

    test('production() creates minimal settings with redaction', () {
      final settings = ISpectDioInterceptorSettingsBuilder.production().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.printRequestData, false);
      expect(settings.printResponseData, false);
      expect(settings.printErrorData, true);
      expect(settings.printErrorHeaders, true);
      expect(settings.printErrorMessage, true);
    });

    test('staging() creates balanced settings with redaction', () {
      final settings = ISpectDioInterceptorSettingsBuilder.staging().build();

      expect(settings.enabled, true);
      expect(settings.enableRedaction, true);
      expect(settings.printRequestData, true);
      expect(settings.printErrorData, true);
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

    test('withErrorsOnly() disables request/response logging', () {
      final settings =
          ISpectDioInterceptorSettingsBuilder().withErrorsOnly().build();

      expect(settings.printRequestData, false);
      expect(settings.printRequestHeaders, false);
      expect(settings.printResponseData, false);
      expect(settings.printResponseHeaders, false);
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
      expect(settings.printRequestData, false); // overridden by withErrorsOnly
    });
  });
}
